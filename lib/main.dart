import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShinobiApp());
}

class ShinobiApp extends StatelessWidget {
  const ShinobiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shinobi Lootr',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF101216),
        primaryColor: const Color(0xFFFF9800),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF9800),
          secondary: Color(0xFF00E676),
          surface: Color(0xFF171A21),
        ),
        fontFamily: 'Roboto',
      ),
      home: const ShinobiScreen(),
    );
  }
}

class ZoneData {
  final String id;
  final String name;
  final String description;
  final int minLevel;
  final List<EnemyTemplate> enemies;
  final EnemyTemplate boss;

  const ZoneData({
    required this.id,
    required this.name,
    required this.description,
    required this.minLevel,
    required this.enemies,
    required this.boss,
  });
}

class ShinobiScreen extends StatefulWidget {
  const ShinobiScreen({super.key});

  @override
  State<ShinobiScreen> createState() => _ShinobiScreenState();
}

class _ShinobiScreenState extends State<ShinobiScreen> {
  final Random _rng = Random();

  // Podstawowe statystyki gracza
  int level = 1;
  int exp = 0;
  int maxExp = 100;
  int hp = 120;
  int maxHp = 120;
  int chakra = 80;
  int maxChakra = 80;
  int ryo = 300;
  String currentRank = 'Nowicjusz Akademii';

  // Eksploracja stref
  String currentZoneId = 'gate';
  int currentZoneDepth = 0;
  final Map<String, int> zoneCheckpoints = {
    'gate': 0,
    'forest': 0,
    'bridge': 0,
    'valley': 0,
    'hideout': 0,
  };

  // Logi
  final List<String> battleLogs = [];
  final List<String> adventureLogs = [];

  // Modyfikatory tymczasowe / pasywne
  int bonusAtk = 5;
  int bonusDef = 2;
  int shieldBonusDef = 0;
  int passiveHpRegen = 0;
  int passiveCpRegen = 0;

  // Ekwipunek gracza
  late EquipmentItem currentWeapon;
  late EquipmentItem currentHelmet;
  late EquipmentItem currentArmor;
  late EquipmentItem currentBoots;
  late EquipmentItem currentTrinket;
  final List<EquipmentItem> inventory = [];

  // Techniki Jutsu
  late Jutsu activeJutsu1;
  late Jutsu activeJutsu2;
  late Jutsu activeJutsu3;
  final List<Jutsu> learnedJutsuList = [];

  // Systemy Bingo Book i Milestones
  late List<BingoTarget> bingoTargets;
  MilestoneTracker milestones = MilestoneTracker();

  // Bazy danych stref i technik
  late List<ZoneData> zones;
  late List<Jutsu> allAvailableJutsus;

  // --- STATYSTYKI WYPOSAŻENIA I BONUSY ---
  // Nowy podział: Broń + Głowa = Atak | Pancerz + Buty = Obrona | Talizman = Moc Jutsu %
  int get totalAttack =>
      currentWeapon.effectiveStat +
      currentHelmet.effectiveStat +
      bonusAtk +
      setBonusAtk +
      milestoneBonusAtk +
      beltBonusAtk +
      level;

  int get totalDefense =>
      currentArmor.effectiveStat +
      currentBoots.effectiveStat +
      bonusDef +
      setBonusDef +
      milestoneBonusDef +
      beltBonusDef;

  int get totalJutsuPower => currentTrinket.effectiveStat + beltBonusJutsuPower;
  int get totalDodgeRate => min(35, 5 + milestoneBonusDodge + beltBonusDodge);
  int get totalCritRate => min(40, 8 + beltBonusCrit);

  // Bonusy z Kamieni Milowych (Milestones)
  int get milestoneBonusAtk => (milestones.physicalHitsDealt ~/ 40) * 2;
  int get milestoneBonusDef => (milestones.damageTaken ~/ 120) * 2;
  int get milestoneBonusDodge => min(15, (milestones.enemiesSlain ~/ 25) * 2);
  int get milestoneBonusMaxCp => (milestones.jutsuCasts ~/ 20) * 5;

  // Bonusy z Pasów Rangowych
  int get beltBonusAtk {
    int b = 0;
    if (level >= 10) b += 5; // Zielony Pas Genina
    if (milestones.bountiesClaimed >= 3 && currentZoneDepth >= 100) b += 10; // Czarny Pas Jōnina
    return b;
  }

  int get beltBonusDef {
    int b = 0;
    if (level >= 10) b += 5; // Zielony Pas Genina
    return b;
  }

  int get beltBonusJutsuPower {
    int b = 0;
    if (currentRank == 'Chūnin' || currentRank == 'Jōnin' || currentRank == 'Sannin') b += 5; // Niebieski Pas Chūnina
    if (currentRank == 'Sannin') b += 15; // Szkarłatny Pas Sannina
    return b;
  }

  int get beltBonusDodge {
    int b = 0;
    if (milestones.bountiesClaimed >= 3 && currentZoneDepth >= 100) b += 5; // Czarny Pas Jōnina
    return b;
  }

  int get beltBonusCrit {
    int b = 0;
    if (currentRank == 'Sannin') b += 10; // Szkarłatny Pas Sannina
    return b;
  }

  // Bonusy Zestawowe (Set Groups)
  int get setBonusAtk {
    int countANBU = 0;
    if (currentWeapon.setGroup == 'ANBU') countANBU++;
    if (currentHelmet.setGroup == 'ANBU') countANBU++;
    if (currentArmor.setGroup == 'ANBU') countANBU++;
    if (currentBoots.setGroup == 'ANBU') countANBU++;
    if (currentTrinket.setGroup == 'ANBU') countANBU++;
    return countANBU >= 3 ? 15 : 0;
  }

  int get setBonusDef {
    int countMyoboku = 0;
    if (currentWeapon.setGroup == 'Myoboku') countMyoboku++;
    if (currentHelmet.setGroup == 'Myoboku') countMyoboku++;
    if (currentArmor.setGroup == 'Myoboku') countMyoboku++;
    if (currentBoots.setGroup == 'Myoboku') countMyoboku++;
    if (currentTrinket.setGroup == 'Myoboku') countMyoboku++;
    return countMyoboku >= 3 ? 15 : 0;
  }

  @override
  void initState() {
    super.initState();
    _initDefaultLoadout();
    _initJutsuDatabase();
    _initZonesDatabase();
    _initBingoBook();
    _loadGameData();
  }

  void _initDefaultLoadout() {
    currentWeapon = const EquipmentItem(
      id: 'w_init',
      name: 'Stalowy Kunai Bojowy',
      slot: GearSlot.weapon,
      rarity: ItemRarity.common,
      baseStat: 15,
      price: 60,
    );
    currentHelmet = const EquipmentItem(
      id: 'h_init',
      name: 'Ochraniacz Czoła Liścia',
      slot: GearSlot.helmet,
      rarity: ItemRarity.common,
      baseStat: 10,
      price: 50,
    );
    currentArmor = const EquipmentItem(
      id: 'a_init',
      name: 'Kamizelka Treningowa',
      slot: GearSlot.armor,
      rarity: ItemRarity.common,
      baseStat: 14,
      price: 60,
    );
    currentBoots = const EquipmentItem(
      id: 'b_init',
      name: 'Sandały Shinobi',
      slot: GearSlot.boots,
      rarity: ItemRarity.common,
      baseStat: 8,
      price: 45,
    );
    currentTrinket = const EquipmentItem(
      id: 't_init',
      name: 'Amulet Przepływu Czakry',
      slot: GearSlot.trinket,
      rarity: ItemRarity.common,
      baseStat: 10,
      price: 80,
    );
  }

  void _initJutsuDatabase() {
    allAvailableJutsus = const [
      Jutsu(
        id: 'j_taijutsu',
        name: 'Taijutsu: Seria Ciosów',
        rank: JutsuRank.academy,
        type: JutsuType.damage,
        chakraCost: 15,
        powerMultiplier: 1.4,
        description: 'Szybkie uderzenie wręcz omijające część obrony wroga.',
        value: 120,
      ),
      Jutsu(
        id: 'j_bunshin',
        name: 'Bunshin no Jutsu: Klon Czakry',
        rank: JutsuRank.academy,
        type: JutsuType.shield,
        chakraCost: 20,
        powerMultiplier: 1.5,
        description: 'Tworzy iluzję absorbującą kolejne uderzenie wroga.',
        value: 150,
      ),
      Jutsu(
        id: 'j_fireball',
        name: 'Katon: Kula Ognia',
        rank: JutsuRank.genin,
        type: JutsuType.damage,
        chakraCost: 28,
        powerMultiplier: 2.1,
        description: 'Potężny strumień płomieni wypalający pancerz.',
        value: 300,
      ),
      Jutsu(
        id: 'j_waterbullet',
        name: 'Suiton: Wodna Kula',
        rank: JutsuRank.genin,
        type: JutsuType.damage,
        chakraCost: 26,
        powerMultiplier: 2.0,
        description: 'Pocisk sprężonej wody uderzający z impetem.',
        value: 280,
      ),
      Jutsu(
        id: 'j_heal',
        name: 'Iryōjutsu: Regeneracja Dłoni',
        rank: JutsuRank.genin,
        type: JutsuType.heal,
        chakraCost: 30,
        powerMultiplier: 2.2,
        description: 'Medyczna czakra przywracająca znaczne punkty zdrowia.',
        value: 350,
      ),
      Jutsu(
        id: 'j_chidori',
        name: 'Raiton: Chidori (Tysiąc Ptaków)',
        rank: JutsuRank.chunin,
        type: JutsuType.damage,
        chakraCost: 45,
        powerMultiplier: 3.2,
        description: 'Błyskawiczne pchnięcie piorunem niszczące obronę celu.',
        value: 750,
      ),
      Jutsu(
        id: 'j_rasengan',
        name: 'Ninjutsu: Rasengan',
        rank: JutsuRank.chunin,
        type: JutsuType.damage,
        chakraCost: 45,
        powerMultiplier: 3.3,
        description: 'Wirująca sfera czakry rozbijająca cel na kawałki.',
        value: 800,
      ),
      Jutsu(
        id: 'j_earthwall',
        name: 'Doton: Kamienny Mur',
        rank: JutsuRank.chunin,
        type: JutsuType.shield,
        chakraCost: 35,
        powerMultiplier: 2.6,
        description: 'Wznosi potężną ścianę z ziemi znacznie redukującą ciosy.',
        value: 650,
      ),
      Jutsu(
        id: 'j_dragon_fire',
        name: 'Katon: Smoczy Płomień',
        rank: JutsuRank.jonin,
        type: JutsuType.damage,
        chakraCost: 65,
        powerMultiplier: 4.2,
        description: 'Piekielny strumień ognia trawiący całe pole bitwy.',
        value: 1500,
      ),
      Jutsu(
        id: 'j_water_dragon',
        name: 'Suiton: Wodny Smok',
        rank: JutsuRank.jonin,
        type: JutsuType.damage,
        chakraCost: 65,
        powerMultiplier: 4.1,
        description: 'Gigantyczna bestia z wody miażdżąca pozycje wroga.',
        value: 1450,
      ),
      Jutsu(
        id: 'j_shadow_clone_barrage',
        name: 'Kage Bunshin: Wielka Nawałnica',
        rank: JutsuRank.jonin,
        type: JutsuType.damage,
        chakraCost: 70,
        powerMultiplier: 4.4,
        description: 'Dziesiątki klonów cienia wyprowadzających grad uderzeń.',
        value: 1600,
      ),
      Jutsu(
        id: 'j_katsuyu_heal',
        name: 'Kuchiyose: Dar Katsuyu',
        rank: JutsuRank.jonin,
        type: JutsuType.heal,
        chakraCost: 55,
        powerMultiplier: 4.0,
        description: 'Medyczna ślina ślimaka przywracająca ogromne ilości zdrowia.',
        value: 1500,
      ),
      Jutsu(
        id: 'j_rasenshuriken',
        name: 'Fūton: Rasenshuriken',
        rank: JutsuRank.sannin,
        type: JutsuType.damage,
        chakraCost: 100,
        powerMultiplier: 6.2,
        description: 'Legendarna wirująca broń wiatru przecinająca nici czakry.',
        value: 3500,
      ),
      Jutsu(
        id: 'j_kirin',
        name: 'Raiton: Kirin (Rycząca Bestia)',
        rank: JutsuRank.sannin,
        type: JutsuType.damage,
        chakraCost: 95,
        powerMultiplier: 6.0,
        description: 'Prawdziwy piorun ściągnięty z chmur z prędkością światła.',
        value: 3400,
      ),
      Jutsu(
        id: 'j_byakugou',
        name: 'Fūinjutsu: Pieczęć Siły Stu',
        rank: JutsuRank.sannin,
        type: JutsuType.heal,
        chakraCost: 80,
        powerMultiplier: 5.5,
        description: 'Natychmiastowe odblokowanie zapasów czakry i pełna regeneracja.',
        value: 3800,
      ),
      Jutsu(
        id: 'j_sand_coffin',
        name: 'Sabaku: Pustynne Więzienie',
        rank: JutsuRank.jonin,
        type: JutsuType.damage,
        chakraCost: 75,
        powerMultiplier: 4.6,
        description: 'Bezlitosny uścisk sprężonego piasku łamiący kości.',
        value: 1800,
      ),
      Jutsu(
        id: 'j_reaper_seal',
        name: 'Kinjutsu: Pieczęć Śmierci',
        rank: JutsuRank.sannin,
        type: JutsuType.damage,
        chakraCost: 120,
        powerMultiplier: 7.5,
        description: 'Wezwanie Boga Śmierci Shiki Fūjin niszczącego duszę wroga.',
        value: 5000,
      ),
    ];

    activeJutsu1 = allAvailableJutsus[0]; // Taijutsu
    activeJutsu2 = allAvailableJutsus[2]; // Kula Ognia
    activeJutsu3 = allAvailableJutsus[4]; // Regeneracja Dłoni
    learnedJutsuList.addAll([activeJutsu1, activeJutsu2, activeJutsu3]);
  }

  void _initZonesDatabase() {
    zones = [
      ZoneData(
        id: 'gate',
        name: 'Brama Wioski Liścia',
        description: 'Obrzeża Konohy. Dzikie ogary i drobni złodzieje.',
        minLevel: 1,
        enemies: const [
          EnemyTemplate(id: 'e_dog', name: 'Dziki Ogar z Lasu', maxHp: 65, baseAtk: 12, baseDef: 6),
          EnemyTemplate(id: 'e_thief', name: 'Złodziej Zapieczętowanych Zwojów', maxHp: 80, baseAtk: 16, baseDef: 8),
          EnemyTemplate(id: 'e_scout_spy', name: 'Szpieg Trawiastej Mgły', maxHp: 95, baseAtk: 18, baseDef: 10),
        ],
        boss: const EnemyTemplate(
          id: 'b_mizuki',
          name: 'Zdrajca Mizuki',
          maxHp: 220,
          baseAtk: 24,
          baseDef: 14,
          traits: [BossTrait.dodgeManiac],
          isBoss: true,
        ),
      ),
      ZoneData(
        id: 'forest',
        name: 'Las Śmierci (Egzamin Chūnina)',
        description: 'Gęsta dżungla pełna jadowitych bestii i wrogich drużyn.',
        minLevel: 8,
        enemies: const [
          EnemyTemplate(id: 'e_leech', name: 'Wielka Pijawka Czakry', maxHp: 150, baseAtk: 26, baseDef: 14, traits: [BossTrait.chakraLeech]),
          EnemyTemplate(id: 'e_rain_genin', name: 'Genin Ukrytego Deszczu', maxHp: 180, baseAtk: 30, baseDef: 18),
          EnemyTemplate(id: 'e_snake', name: 'Olbrzymi Pyton Śmierci', maxHp: 210, baseAtk: 34, baseDef: 20, traits: [BossTrait.poisonMaster]),
        ],
        boss: const EnemyTemplate(
          id: 'b_dosu',
          name: 'Dosu Kinuta (Dźwięk)',
          maxHp: 480,
          baseAtk: 42,
          baseDef: 26,
          traits: [BossTrait.chakraThorns, BossTrait.ironSkin],
          isBoss: true,
        ),
      ),
      ZoneData(
        id: 'bridge',
        name: 'Wielki Most Tenkū (Kraj Fali)',
        description: 'Most spowity lodowatą mgłą. Rewir bezlitosnych najemników.',
        minLevel: 16,
        enemies: const [
          EnemyTemplate(id: 'e_mist_thug', name: 'Najemnik Gato z Tasakiem', maxHp: 260, baseAtk: 45, baseDef: 28),
          EnemyTemplate(id: 'e_hunter_ninja', name: 'Tropiciel Kirigakure (ANBU)', maxHp: 320, baseAtk: 52, baseDef: 34, traits: [BossTrait.dodgeManiac]),
        ],
        boss: const EnemyTemplate(
          id: 'b_zabuza',
          name: 'Zabuza Momochi (Demon Mgły)',
          maxHp: 850,
          baseAtk: 68,
          baseDef: 42,
          traits: [BossTrait.bloodEnrage, BossTrait.ironSkin],
          isBoss: true,
        ),
      ),
      ZoneData(
        id: 'valley',
        name: 'Dolina Końca',
        description: 'Pradawne wodospady i zniszczone pomniki założycieli.',
        minLevel: 25,
        enemies: const [
          EnemyTemplate(id: 'e_curse_warrior', name: 'Nosiciel Przeklętej Pieczęci', maxHp: 450, baseAtk: 68, baseDef: 48, traits: [BossTrait.bloodEnrage]),
          EnemyTemplate(id: 'e_sound_four', name: 'Elitarny Strażnik Dźwięku', maxHp: 520, baseAtk: 76, baseDef: 54, traits: [BossTrait.chakraLeech]),
        ],
        boss: const EnemyTemplate(
          id: 'b_gaara',
          name: 'Gaara Pustynnego Piasku',
          maxHp: 1350,
          baseAtk: 92,
          baseDef: 70,
          traits: [BossTrait.ironSkin, BossTrait.chakraThorns],
          isBoss: true,
        ),
      ),
      ZoneData(
        id: 'hideout',
        name: 'Kryjówka Akatsuki',
        description: 'Mroczne podziemia organizacji polującej na ogoniaste bestie.',
        minLevel: 35,
        enemies: const [
          EnemyTemplate(id: 'e_white_zetsu', name: 'Armia Białych Zetsu', maxHp: 700, baseAtk: 95, baseDef: 65, traits: [BossTrait.chakraLeech, BossTrait.dodgeManiac]),
          EnemyTemplate(id: 'e_puppet_renegade', name: 'Zbiegły Lalkarz Piasku', maxHp: 820, baseAtk: 110, baseDef: 72, traits: [BossTrait.poisonMaster]),
        ],
        boss: const EnemyTemplate(
          id: 'b_itachi_clone',
          name: 'Klon Cienia Itachiego Uchiha',
          maxHp: 2100,
          baseAtk: 135,
          baseDef: 85,
          traits: [BossTrait.dodgeManiac, BossTrait.bloodEnrage, BossTrait.chakraThorns],
          isBoss: true,
        ),
      ),
    ];
  }

  void _initBingoBook() {
    bingoTargets = [
      BingoTarget(
        id: 'nukenin_1',
        name: 'Mei Ukryty Cień',
        title: 'Zbiegły Zwiadowca Liścia',
        zoneId: 'gate',
        minDepth: 25,
        enemy: const EnemyTemplate(
          id: 'e_mei',
          name: 'Mei Ukryty Cień',
          maxHp: 260,
          baseAtk: 25,
          baseDef: 14,
          traits: [BossTrait.dodgeManiac],
          isBoss: true,
        ),
        exclusiveReward: const EquipmentItem(
          id: 'drop_mei_boots',
          name: 'Ciche Kamasze Mglistego Widma',
          slot: GearSlot.boots,
          rarity: ItemRarity.epic,
          baseStat: 26,
          specialEffect: 'Mistrzowskie Zmylenie: Po uniku darmowe Jutsu',
          price: 600,
        ),
        bountyRyo: 400,
        bountyExp: 300,
      ),
      BingoTarget(
        id: 'nukenin_2',
        name: 'Juzo Żelaznoręki',
        title: 'Przemytnik Broni z Iwa',
        zoneId: 'forest',
        minDepth: 50,
        enemy: const EnemyTemplate(
          id: 'e_juzo',
          name: 'Juzo Żelaznoręki',
          maxHp: 460,
          baseAtk: 36,
          baseDef: 26,
          traits: [BossTrait.ironSkin, BossTrait.poisonMaster],
          isBoss: true,
        ),
        exclusiveReward: const EquipmentItem(
          id: 'drop_juzo_armor',
          name: 'Żelazna Kolczuga Przemytnika',
          slot: GearSlot.armor,
          rarity: ItemRarity.epic,
          baseStat: 38,
          specialEffect: 'Antytoksyna: Pancerz redukuje trucizny',
          price: 900,
        ),
        bountyRyo: 750,
        bountyExp: 550,
      ),
      BingoTarget(
        id: 'nukenin_3',
        name: 'Ryōgo „Krwawa Brzytwa”',
        title: 'Rzeźnik z Kraju Fali',
        zoneId: 'bridge',
        minDepth: 50,
        enemy: const EnemyTemplate(
          id: 'e_ryogo',
          name: 'Ryōgo „Krwawa Brzytwa”',
          maxHp: 640,
          baseAtk: 52,
          baseDef: 22,
          traits: [BossTrait.bloodEnrage, BossTrait.dodgeManiac],
          isBoss: true,
        ),
        exclusiveReward: const EquipmentItem(
          id: 'drop_ryogo_blade',
          name: 'Ząbkowany Sztylet Krwawej Brzytwy',
          slot: GearSlot.weapon,
          rarity: ItemRarity.legendary,
          baseStat: 56,
          specialEffect: 'Krwawiące Cięcie: Krytyki nakładają krwawienie',
          price: 1500,
        ),
        bountyRyo: 1200,
        bountyExp: 900,
      ),
      BingoTarget(
        id: 'nukenin_4',
        name: 'Gurenko Ognisty Pająk',
        title: 'Zdrajca z Doliny Końca',
        zoneId: 'valley',
        minDepth: 75,
        enemy: const EnemyTemplate(
          id: 'e_gurenko',
          name: 'Gurenko Ognisty Pająk',
          maxHp: 820,
          baseAtk: 60,
          baseDef: 32,
          traits: [BossTrait.chakraLeech, BossTrait.chakraThorns],
          isBoss: true,
        ),
        exclusiveReward: const EquipmentItem(
          id: 'drop_gurenko_talisman',
          name: 'Ognisty Kokon Gurenko',
          slot: GearSlot.trinket,
          rarity: ItemRarity.legendary,
          baseStat: 45,
          specialEffect: 'Pożeracz Czakry: Wzmocnienie Jutsu i kradzież CP',
          price: 2200,
        ),
        bountyRyo: 1800,
        bountyExp: 1400,
      ),
      BingoTarget(
        id: 'nukenin_5',
        name: 'Kenshin Upadły Mistrz Miecza',
        title: 'Egzekutor Cienia',
        zoneId: 'hideout',
        minDepth: 100,
        enemy: const EnemyTemplate(
          id: 'e_kenshin',
          name: 'Kenshin Upadły Mistrz Miecza',
          maxHp: 1250,
          baseAtk: 84,
          baseDef: 40,
          traits: [BossTrait.ironSkin, BossTrait.bloodEnrage, BossTrait.chakraLeech],
          isBoss: true,
        ),
        exclusiveReward: const EquipmentItem(
          id: 'drop_kenshin_helm',
          name: 'Pęknięta Maska Skrytobójcy',
          slot: GearSlot.helmet,
          rarity: ItemRarity.legendary,
          baseStat: 52,
          specialEffect: 'Zabójczy Instynkt: Potężny bonus do Ataku',
          price: 3000,
        ),
        bountyRyo: 2800,
        bountyExp: 2200,
      ),
    ];
  }
  void _saveGameData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('level', level);
    prefs.setInt('exp', exp);
    prefs.setInt('maxExp', maxExp);
    prefs.setInt('hp', hp);
    prefs.setInt('maxHp', maxHp);
    prefs.setInt('chakra', chakra);
    prefs.setInt('maxChakra', maxChakra);
    prefs.setInt('ryo', ryo);
    prefs.setString('rank', currentRank);
    prefs.setString('milestones', jsonEncode(milestones.toJson()));

    prefs.setString('weapon', jsonEncode(currentWeapon.toJson()));
    prefs.setString('helmet', jsonEncode(currentHelmet.toJson()));
    prefs.setString('armor', jsonEncode(currentArmor.toJson()));
    prefs.setString('boots', jsonEncode(currentBoots.toJson()));
    prefs.setString('trinket', jsonEncode(currentTrinket.toJson()));

    final invList = inventory.map((i) => i.toJson()).toList();
    prefs.setString('inventory', jsonEncode(invList));

    final learnedList = learnedJutsuList.map((j) => j.toJson()).toList();
    prefs.setString('learned_jutsu', jsonEncode(learnedList));
    prefs.setString('j1', jsonEncode(activeJutsu1.toJson()));
    prefs.setString('j2', jsonEncode(activeJutsu2.toJson()));
    prefs.setString('j3', jsonEncode(activeJutsu3.toJson()));

    final cpMap = {for (var e in zoneCheckpoints.entries) e.key: e.value};
    prefs.setString('zone_checkpoints', jsonEncode(cpMap));

    final bingoStates = {for (var b in bingoTargets) b.id: b.isDefeated};
    prefs.setString('bingo_states', jsonEncode(bingoStates));
  }

  void _loadGameData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      level = prefs.getInt('level') ?? level;
      exp = prefs.getInt('exp') ?? exp;
      maxExp = prefs.getInt('maxExp') ?? maxExp;
      hp = prefs.getInt('hp') ?? hp;
      maxHp = prefs.getInt('maxHp') ?? maxHp;
      chakra = prefs.getInt('chakra') ?? chakra;
      maxChakra = prefs.getInt('maxChakra') ?? maxChakra;
      ryo = prefs.getInt('ryo') ?? ryo;
      currentRank = prefs.getString('rank') ?? currentRank;

      final mStr = prefs.getString('milestones');
      if (mStr != null) {
        milestones = MilestoneTracker.fromJson(jsonDecode(mStr));
      }

      final wStr = prefs.getString('weapon');
      if (wStr != null) currentWeapon = EquipmentItem.fromJson(jsonDecode(wStr));
      final hStr = prefs.getString('helmet');
      if (hStr != null) currentHelmet = EquipmentItem.fromJson(jsonDecode(hStr));
      final aStr = prefs.getString('armor');
      if (aStr != null) currentArmor = EquipmentItem.fromJson(jsonDecode(aStr));
      final bStr = prefs.getString('boots');
      if (bStr != null) currentBoots = EquipmentItem.fromJson(jsonDecode(bStr));
      final tStr = prefs.getString('trinket');
      if (tStr != null) currentTrinket = EquipmentItem.fromJson(jsonDecode(tStr));

      final invStr = prefs.getString('inventory');
      if (invStr != null) {
        final List list = jsonDecode(invStr);
        inventory.clear();
        for (var item in list) {
          inventory.add(EquipmentItem.fromJson(item));
        }
      }

      final jutsuStr = prefs.getString('learned_jutsu');
      if (jutsuStr != null) {
        final List list = jsonDecode(jutsuStr);
        learnedJutsuList.clear();
        for (var j in list) {
          learnedJutsuList.add(Jutsu.fromJson(j));
        }
      }

      final j1Str = prefs.getString('j1');
      if (j1Str != null) activeJutsu1 = Jutsu.fromJson(jsonDecode(j1Str));
      final j2Str = prefs.getString('j2');
      if (j2Str != null) activeJutsu2 = Jutsu.fromJson(jsonDecode(j2Str));
      final j3Str = prefs.getString('j3');
      if (j3Str != null) activeJutsu3 = Jutsu.fromJson(jsonDecode(j3Str));

      final cpStr = prefs.getString('zone_checkpoints');
      if (cpStr != null) {
        final Map<String, dynamic> map = jsonDecode(cpStr);
        map.forEach((k, v) => zoneCheckpoints[k] = v as int);
      }

      final bStates = prefs.getString('bingo_states');
      if (bStates != null) {
        final map = jsonDecode(bStates) as Map<String, dynamic>;
        for (var target in bingoTargets) {
          if (map.containsKey(target.id)) {
            target.isDefeated = map[target.id] as bool;
          }
        }
      }
    });
  }

  void _addExp(int amount) {
    exp += amount;
    while (exp >= maxExp) {
      exp -= maxExp;
      level++;
      maxExp = (maxExp * 1.35).round();
      maxHp += 18;
      maxChakra += 10;
      hp = maxHp;
      chakra = maxChakra;
      adventureLogs.insert(0, '🎉 Awans na Poziom $level! Zdrowie i Czakra odnowione!');
    }
  }

  void _applyTurnRegen() {
    if (passiveHpRegen > 0) {
      hp = min(maxHp, hp + passiveHpRegen);
      battleLogs.insert(0, '💚 Regeneracja: +$passiveHpRegen HP.');
    }
    if (passiveCpRegen > 0) {
      chakra = min(maxChakra + milestoneBonusMaxCp, chakra + passiveCpRegen);
      battleLogs.insert(0, '🌀 Regeneracja: +$passiveCpRegen CP.');
    }
  }

  void returnToVillage({bool fallenInBattle = false}) {
    setState(() {
      currentZoneDepth = 0;
      if (fallenInBattle) {
        hp = 1;
        adventureLogs.insert(0, '💀 Poległeś w starciu... Sanitariusze przenieśli Cię do Wioski z 1 HP.');
      } else {
        adventureLogs.insert(0, '🏡 Bezpiecznie powróciłeś do Wioski Liścia.');
      }
      _saveGameData();
    });
  }

  void _stepForwardInZone() {
    final curZone = zones.firstWhere((z) => z.id == currentZoneId);
    setState(() {
      currentZoneDepth += 5;
      adventureLogs.insert(0, '👣 ${curZone.name} – Głębokość: $currentZoneDepth kroków.');

      // Checkpointy co 50 kroków
      if (currentZoneDepth % 50 == 0 && currentZoneDepth > (zoneCheckpoints[currentZoneId] ?? 0)) {
        zoneCheckpoints[currentZoneId] = currentZoneDepth;
        adventureLogs.insert(0, '🚩 Zabezpieczono nowy posterunek zwiadowczy na głębokości $currentZoneDepth!');
      }

      // Szansa na wytropienie Nukenina z Bingo Book
      final availableBounties = bingoTargets
          .where((b) => !b.isDefeated && b.zoneId == currentZoneId && currentZoneDepth >= b.minDepth)
          .toList();

      if (availableBounties.isNotEmpty && _rng.nextInt(100) < 30) {
        final target = availableBounties[_rng.nextInt(availableBounties.length)];
        adventureLogs.insert(0, '⚠️ Czujesz obcą morderczą czakrę! Wytropiono zbiega: ${target.name}!');
        _startBattleWithEnemy(target.enemy, bounty: target);
        return;
      }

      // Boss strefy na progach 100, 200, 300...
      if (currentZoneDepth > 0 && currentZoneDepth % 100 == 0) {
        adventureLogs.insert(0, '🔥 Droga zablokowana! Wyłania się boss lokacji: ${curZone.boss.name}!');
        _startBattleWithEnemy(curZone.boss, isZoneBoss: true);
        return;
      }

      // Zwykłe starcie lub zdarzenie zwiadowcze
      if (_rng.nextInt(100) < 60) {
        final template = curZone.enemies[_rng.nextInt(curZone.enemies.length)];
        final scaledEnemy = EnemyTemplate(
          id: '${template.id}_$currentZoneDepth',
          name: '${template.name} (Głęb. $currentZoneDepth)',
          maxHp: template.maxHp + (currentZoneDepth * 3),
          baseAtk: template.baseAtk + (currentZoneDepth ~/ 4),
          baseDef: template.baseDef + (currentZoneDepth ~/ 6),
          traits: template.traits,
        );
        _startBattleWithEnemy(scaledEnemy);
      } else {
        final foundRyo = 25 + _rng.nextInt(40) + (currentZoneDepth ~/ 2);
        ryo += foundRyo;
        adventureLogs.insert(0, '💰 Odnaleziono porzucony ekwipunek warty $foundRyo Ryo!');
      }
    });
  }

  void _startBattleWithEnemy(
    EnemyTemplate template, {
    BingoTarget? bounty,
    bool isZoneBoss = false,
    bool isExamFight = false,
  }) {
    int enemyHp = template.maxHp;
    battleLogs.clear();
    battleLogs.insert(0, '⚔️ Początek walki z: ${template.name}!');

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0xFF14161C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setBattleState) {
            void appendBattleLog(String log) {
              setBattleState(() {
                battleLogs.insert(0, log);
              });
            }

            void enemyTurn() {
              if (enemyHp <= 0) return;

              // Kawarimi gracza
              if (_rng.nextInt(100) < totalDodgeRate) {
                appendBattleLog('🪵 Kawarimi! Zastąpiłeś się kłodą i uniknąłeś ciosu!');
                _applyTurnRegen();
                setBattleState(() {});
                return;
              }

              bool isEnemyCrit = _rng.nextInt(100) < template.critRate;
              double eCritMult = isEnemyCrit ? 1.5 : 1.0;

              // Cecha: Szał Krwi (Blood Enrage)
              double enrageBonus = 1.0;
              if (template.traits.contains(BossTrait.bloodEnrage) &&
                  (enemyHp / template.maxHp) <= 0.35) {
                enrageBonus = 1.5;
                appendBattleLog('🩸 ${template.name} wpada w SZAŁ KRWI! Obrażenia +50%!');
              }

              final effectivePlayerDef = (totalDefense + shieldBonusDef);
              final rawDmg = ((template.baseAtk * enrageBonus + _rng.nextInt(5)) * eCritMult).round();
              final dmg = max(3, rawDmg - (effectivePlayerDef ~/ 2));

              setState(() {
                hp = max(0, hp - dmg);
                milestones.damageTaken += dmg;
              });

              if (isEnemyCrit) {
                appendBattleLog('💥 KRYTYK WROGA! ${template.name} zadaje $dmg obrażeń!');
              } else {
                appendBattleLog('${template.name} atakuje i zadaje $dmg obrażeń.');
              }

              // Cecha: Pijawka Czakry (Chakra Leech)
              if (template.traits.contains(BossTrait.chakraLeech)) {
                final leech = min(chakra, 12);
                chakra -= leech;
                enemyHp = min(template.maxHp, enemyHp + leech);
                appendBattleLog('🌀 Pijawka Czakry wysysa $leech CP i uzdrawia wroga!');
              }

              // Cecha: Mistrz Trucizn (Poison Master)
              if (template.traits.contains(BossTrait.poisonMaster)) {
                final poisonDmg = max(2, (maxHp * 0.04).round());
                setState(() => hp = max(0, hp - poisonDmg));
                appendBattleLog('🧪 Trucizna wypala Twoje żyły! -$poisonDmg HP.');
              }

              shieldBonusDef = 0;

              // SPRAWDZENIE ŚMIERCI PRZED REGENERACJĄ (NAPRAWIONY BŁĄD REANIMACJI)
              if (hp <= 0) {
                _saveGameData();
                Navigator.pop(ctx);
                if (isExamFight) {
                  setState(() => hp = 1);
                  adventureLogs.insert(0, '❌ Egzamin oblany! Wróć silniejszy.');
                } else {
                  returnToVillage(fallenInBattle: true);
                }
                return;
              }

              _applyTurnRegen();
              _saveGameData();
            }

            void executeJutsu(Jutsu jutsu) {
              if (chakra < jutsu.chakraCost) {
                appendBattleLog('❌ Za mało czakry na: ${jutsu.name}!');
                setBattleState(() {});
                return;
              }

              setState(() {
                chakra -= jutsu.chakraCost;
                milestones.jutsuCasts++;
              });

              // Jutsu Medyczne (Heal)
              if (jutsu.type == JutsuType.heal) {
                final healAmount = ((35 + (totalJutsuPower * 0.9)) * jutsu.powerMultiplier).round();
                setState(() {
                  hp = min(maxHp, hp + healAmount);
                });
                appendBattleLog('💚 ${jutsu.name} odnawia $healAmount punktów życia!');
                enemyTurn();
                setBattleState(() {});
                return;
              }

              // Jutsu Ochronne (Shield)
              if (jutsu.type == JutsuType.shield) {
                shieldBonusDef = (25 * jutsu.powerMultiplier).round();
                appendBattleLog('🛡️ ${jutsu.name} formuje barierę czakry (+${shieldBonusDef} Def)!');
                enemyTurn();
                setBattleState(() {});
                return;
              }

              // SKALOWANIE OBRAŻEŃ: Atak * Mnożnik * MOC JUTSU Z TALIZMANU
              double jutsuScaling = jutsu.powerMultiplier * (1.0 + (totalJutsuPower / 100.0));

              // Cecha: Żelazna Skóra redukuje techniki wręcz
              double traitReduction = 1.0;
              if (template.traits.contains(BossTrait.ironSkin) && jutsu.rank == JutsuRank.academy) {
                traitReduction = 0.55;
                appendBattleLog('🛡️ Żelazna Skóra tłumi obrażenia fizyczne!');
              }

              final dealt = max(
                6,
                ((totalAttack * jutsuScaling * traitReduction).round() - (template.baseDef ~/ 2)),
              );

              enemyHp -= dealt;
              appendBattleLog('🔥 Uderzenie ${jutsu.name}! Zadano $dealt obrażeń!');

              // Cecha: Ciernie Czakry (Chakra Thorns)
              if (template.traits.contains(BossTrait.chakraThorns)) {
                final reflect = max(2, (dealt * 0.15).round());
                setState(() => hp = max(0, hp - reflect));
                appendBattleLog('⚡ Ciernie Czakry odbijają $reflect obrażeń w Twoją stronę!');
                if (hp <= 0) {
                  _saveGameData();
                  Navigator.pop(ctx);
                  returnToVillage(fallenInBattle: true);
                  return;
                }
              }

              if (enemyHp <= 0) {
                _handleVictory(ctx, template, bounty, isZoneBoss, isExamFight);
                return;
              }

              enemyTurn();
              setBattleState(() {});
            }

            void executeBasicAttack() {
              setState(() {
                milestones.physicalHitsDealt++;
              });

              // Kawarimi wroga
              int eDodge = template.dodgeRate + (template.traits.contains(BossTrait.dodgeManiac) ? 20 : 0);
              if (_rng.nextInt(100) < eDodge) {
                appendBattleLog('💨 Wróg zniknął w kłębie dymu (Kawarimi)!');
                enemyTurn();
                setBattleState(() {});
                return;
              }

              bool isCrit = _rng.nextInt(100) < totalCritRate;
              double critMult = isCrit ? 1.5 : 1.0;

              double damageFactor = template.traits.contains(BossTrait.ironSkin) ? 0.5 : 1.0;
              final dealt = max(
                3,
                (((totalAttack * damageFactor + _rng.nextInt(4)) * critMult).round() - (template.baseDef ~/ 2)),
              );

              enemyHp -= dealt;
              if (isCrit) {
                appendBattleLog('💥 KRYTYK! Zwykły cios zadał $dealt obrażeń!');
              } else {
                appendBattleLog('🗡️ Zwykły atak zadał $dealt obrażeń.');
              }

              if (enemyHp <= 0) {
                _handleVictory(ctx, template, bounty, isZoneBoss, isExamFight);
                return;
              }

              enemyTurn();
              setBattleState(() {});
            }

            return Container(
              padding: const EdgeInsets.all(16),
              height: 540,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$enemyHp / ${template.maxHp} HP',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: max(0.0, min(1.0, enemyHp / template.maxHp)),
                    backgroundColor: Colors.white10,
                    color: Colors.redAccent,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('❤️ HP: $hp / $maxHp', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      Text('🌀 CP: $chakra / ${maxChakra + milestoneBonusMaxCp}', style: const TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListView.builder(
                        itemCount: battleLogs.length,
                        itemBuilder: (context, idx) => Text(
                          battleLogs[idx],
                          style: const TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: executeBasicAttack,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF37474F)),
                        child: const Text('Atak Wręcz'),
                      ),
                      ElevatedButton(
                        onPressed: () => executeJutsu(activeJutsu1),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5)),
                        child: Text(activeJutsu1.name),
                      ),
                      ElevatedButton(
                        onPressed: () => executeJutsu(activeJutsu2),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
                        child: Text(activeJutsu2.name),
                      ),
                      ElevatedButton(
                        onPressed: () => executeJutsu(activeJutsu3),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF43A047)),
                        child: Text(activeJutsu3.name),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      returnToVillage();
                    },
                    child: const Text('💨 Wycofaj się do Wioski', style: TextStyle(color: Colors.grey)),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleVictory(
    BuildContext ctx,
    EnemyTemplate enemy,
    BingoTarget? bounty,
    bool isZoneBoss,
    bool isExamFight,
  ) {
    Navigator.pop(ctx);
    setState(() {
      milestones.enemiesSlain++;

      if (isExamFight) {
        if (currentRank == 'Nowicjusz Akademii') currentRank = 'Genin';
        else if (currentRank == 'Genin') currentRank = 'Chūnin';
        else if (currentRank == 'Chūnin') currentRank = 'Jōnin';
        else if (currentRank == 'Jōnin') currentRank = 'Sannin';

        adventureLogs.insert(0, '🎖️ EGZAMIN ZDANY! Uzyskano prestiżową rangę: $currentRank!');
        _saveGameData();
        return;
      }

      int rewardExp = 30 + (currentZoneDepth * 3);
      int rewardRyo = 45 + (currentZoneDepth * 4);

      if (bounty != null) {
        bounty.isDefeated = true;
        milestones.bountiesClaimed++;
        rewardExp += bounty.bountyExp;
        rewardRyo += bounty.bountyRyo;
        inventory.add(bounty.exclusiveReward);
        adventureLogs.insert(0, '🏆 Zlecenie z Bingo Book zrealizowane: ${bounty.name}!');
        adventureLogs.insert(0, '🎁 Zdobyto unikat: ${bounty.exclusiveReward.name}!');
      }

      // Szansa na losowy łup ze zwykłych wrogów lub bossa
      if (isZoneBoss || _rng.nextInt(100) < 35) {
        final drop = _generateRandomLoot(isZoneBoss);
        inventory.add(drop);
        adventureLogs.insert(0, '📦 Zdobyto wyposażenie: ${drop.name} (${drop.rarity.name.toUpperCase()})!');
      }

      ryo += rewardRyo;
      _addExp(rewardExp);
      adventureLogs.insert(0, '⚔️ Zwycięstwo nad ${enemy.name}! (+${rewardRyo} Ryo, +${rewardExp} EXP)');
      _saveGameData();
    });
  }

  EquipmentItem _generateRandomLoot(bool isBossDrop) {
    final slots = GearSlot.values;
    final slot = slots[_rng.nextInt(slots.length)];
    final rarityRoll = _rng.nextInt(100);

    ItemRarity rarity = ItemRarity.common;
    if (isBossDrop || rarityRoll > 85) {
      rarity = ItemRarity.epic;
    } else if (rarityRoll > 60) {
      rarity = ItemRarity.rare;
    }

    int stat = 12 + (currentZoneDepth ~/ 4) + (rarity.index * 10);
    String name = 'Łup Shinobi';
    String? setGroup;

    if (slot == GearSlot.weapon) name = 'Ostrze Bojowe';
    if (slot == GearSlot.helmet) name = 'Kaptur Zwiadowcy';
    if (slot == GearSlot.armor) name = 'Pancerz Ochronny';
    if (slot == GearSlot.boots) name = 'Kamasze Szybkości';
    if (slot == GearSlot.trinket) name = 'Talizman Czakry';

    if (rarity == ItemRarity.epic && _rng.nextBool()) {
      setGroup = _rng.nextBool() ? 'ANBU' : 'Myoboku';
      name += ' [$setGroup]';
    }

    return EquipmentItem(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(999)}',
      name: name,
      slot: slot,
      rarity: rarity,
      baseStat: stat,
      setGroup: setGroup,
      price: stat * 8,
    );
  }
  void _showMilestonesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D24),
        title: const Row(
          children: [
            Icon(Icons.military_tech, color: Colors.amber),
            SizedBox(width: 8),
            Text('Dojo Kamieni Milowych'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text('🥋 PASY RANGOWE KONOHY', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _beltTile('Biały Pas Nowicjusza', 'Początek drogi ninja', '+30 Max HP', true),
              _beltTile('Zielony Pas Genina', 'Osiągnij 10. Poziom', '+5 Atak, +5 Obrona', level >= 10),
              _beltTile('Niebieski Pas Chūnina', 'Ranga Chūnin lub wyższa', '+5% Mocy Jutsu', currentRank != 'Nowicjusz Akademii' && currentRank != 'Genin'),
              _beltTile('Czarny Pas Jōnina', '3 zlecenia Bingo i 100 głębokości', '+10 Atak, +5% Kawarimi', milestones.bountiesClaimed >= 3 && currentZoneDepth >= 100),
              _beltTile('Szkarłatny Pas Sannina', 'Osiągnij Rangę Sannin', '+10% Krytyk, +15% Mocy Jutsu', currentRank == 'Sannin'),
              const Divider(color: Colors.white24, height: 24),
              const Text('🎖️ STATYSTYKI I PROGRES', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _milestoneProgressTile('Zlikwidowani Wrogowie', '${milestones.enemiesSlain} wrogów', '+${milestoneBonusDodge}% Kawarimi'),
              _milestoneProgressTile('Ciosy Fizyczne', '${milestones.physicalHitsDealt} ataków', '+${milestoneBonusAtk} Ataku'),
              _milestoneProgressTile('Użycia Technik Jutsu', '${milestones.jutsuCasts} aktywacji', '+${milestoneBonusMaxCp} Max CP'),
              _milestoneProgressTile('Przyjęte Obrażenia', '${milestones.damageTaken} pkt obrażeń', '+${milestoneBonusDef} Obrony'),
              _milestoneProgressTile('Zrealizowane Listy Gończe', '${milestones.bountiesClaimed} / 5 Nukeninów', 'Dedykowane łupy w plecaku'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zamknij', style: TextStyle(color: Colors.amber)),
          )
        ],
      ),
    );
  }

  void _showBingoBookDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D24),
        title: const Row(
          children: [
            Icon(Icons.menu_book, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Bingo Book (Lista Gończych)'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: bingoTargets.length,
            itemBuilder: (context, idx) {
              final b = bingoTargets[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: b.isDefeated ? Colors.black45 : const Color(0xFF222630),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: b.isDefeated ? Colors.grey : Colors.redAccent.withOpacity(0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          b.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: b.isDefeated ? Colors.grey : Colors.redAccent,
                            decoration: b.isDefeated ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        Text(
                          b.isDefeated ? 'POKONANY' : 'POSZUKIWANY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: b.isDefeated ? Colors.grey : Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(b.title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text('Lokacja: ${b.zoneId.toUpperCase()} | Głębokość: ${b.minDepth}+', style: const TextStyle(fontSize: 11, color: Colors.amber)),
                    Text('Nagroda: ${b.bountyRyo} Ryo | Drop: ${b.exclusiveReward.name}', style: const TextStyle(fontSize: 11, color: Colors.lightBlueAccent)),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zamknij', style: TextStyle(color: Colors.amber)),
          )
        ],
      ),
    );
  }

  void _showInventoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setInvState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1D24),
            title: Text('Plecak Shinobi (${inventory.length} przedmiotów)'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: inventory.isEmpty
                  ? const Center(child: Text('Plecak jest pusty. Ruszaj na misję!'))
                  : ListView.builder(
                      itemCount: inventory.length,
                      itemBuilder: (context, idx) {
                        final item = inventory[idx];
                        return ListTile(
                          title: Text(item.name, style: TextStyle(color: _getRarityColor(item.rarity), fontWeight: FontWeight.bold)),
                          subtitle: Text('${_statLabelForSlot(item.slot)}: +${item.effectiveStat} ${item.specialEffect != null ? '\n✨ ${item.specialEffect}' : ''}'),
                          trailing: Row(
                            mainAxisSize: minAxisSize,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
                                tooltip: 'Załóż',
                                onPressed: () {
                                  _equipItem(item);
                                  setInvState(() {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.monetization_on_outlined, color: Colors.amber),
                                tooltip: 'Sprzedaj',
                                onPressed: () {
                                  setState(() {
                                    ryo += (item.price * 0.6).round();
                                    inventory.removeAt(idx);
                                    _saveGameData();
                                  });
                                  setInvState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Zamknij', style: TextStyle(color: Colors.amber)),
              )
            ],
          );
        },
      ),
    );
  }

  void _equipItem(EquipmentItem item) {
    setState(() {
      inventory.remove(item);
      switch (item.slot) {
        case GearSlot.weapon:
          inventory.add(currentWeapon);
          currentWeapon = item;
          break;
        case GearSlot.helmet:
          inventory.add(currentHelmet);
          currentHelmet = item;
          break;
        case GearSlot.armor:
          inventory.add(currentArmor);
          currentArmor = item;
          break;
        case GearSlot.boots:
          inventory.add(currentBoots);
          currentBoots = item;
          break;
        case GearSlot.trinket:
          inventory.add(currentTrinket);
          currentTrinket = item;
          break;
      }
      _saveGameData();
    });
  }

  void _showBlacksmithDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setForgeState) {
          final equipped = [currentWeapon, currentHelmet, currentArmor, currentBoots, currentTrinket];
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1D24),
            title: const Row(
              children: [
                Icon(Icons.gavel, color: Colors.orangeAccent),
                SizedBox(width: 8),
                Text('Kowal Konohy (Ulepszenia)'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: equipped.length,
                itemBuilder: (context, idx) {
                  final item = equipped[idx];
                  final cost = 80 + (item.upgradeLevel * 60);
                  return ListTile(
                    title: Text('${item.name} (+${item.upgradeLevel})'),
                    subtitle: Text('Aktualnie: ${_statLabelForSlot(item.slot)} +${item.effectiveStat}'),
                    trailing: ElevatedButton(
                      onPressed: ryo < cost
                          ? null
                          : () {
                              setState(() {
                                ryo -= cost;
                                final upgraded = item.copyWith(upgradeLevel: item.upgradeLevel + 1);
                                if (item.slot == GearSlot.weapon) currentWeapon = upgraded;
                                if (item.slot == GearSlot.helmet) currentHelmet = upgraded;
                                if (item.slot == GearSlot.armor) currentArmor = upgraded;
                                if (item.slot == GearSlot.boots) currentBoots = upgraded;
                                if (item.slot == GearSlot.trinket) currentTrinket = upgraded;
                                _saveGameData();
                              });
                              setForgeState(() {});
                            },
                      child: Text('$cost Ryo'),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Zamknij', style: TextStyle(color: Colors.amber)),
              )
            ],
          );
        },
      ),
    );
  }

  void _showExamDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D24),
        title: const Text('Egzaminy Shinobi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Obecna Ranga: $currentRank', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
            const SizedBox(height: 12),
            if (currentRank == 'Nowicjusz Akademii')
              ElevatedButton(
                onPressed: level < 5
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _startBattleWithEnemy(
                          const EnemyTemplate(id: 'ex_genin', name: 'Instruktor Iruka', maxHp: 180, baseAtk: 22, baseDef: 14),
                          isExamFight: true,
                        );
                      },
                child: const Text('Przystąp do Egzaminu na Genina (Wymagany Lvl 5)'),
              ),
            if (currentRank == 'Genin')
              ElevatedButton(
                onPressed: level < 15
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _startBattleWithEnemy(
                          const EnemyTemplate(id: 'ex_chunin', name: 'Egzaminator Baki', maxHp: 480, baseAtk: 46, baseDef: 30, traits: [BossTrait.ironSkin]),
                          isExamFight: true,
                        );
                      },
                child: const Text('Egzamin Chūnina (Wymagany Lvl 15)'),
              ),
            if (currentRank == 'Chūnin')
              ElevatedButton(
                onPressed: level < 28
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _startBattleWithEnemy(
                          const EnemyTemplate(id: 'ex_jonin', name: 'Kakashi Hatake (Kopia)', maxHp: 950, baseAtk: 78, baseDef: 45, traits: [BossTrait.dodgeManiac, BossTrait.bloodEnrage]),
                          isExamFight: true,
                        );
                      },
                child: const Text('Test Kwalifikacyjny na Jōnina (Wymagany Lvl 28)'),
              ),
            if (currentRank == 'Jōnin')
              ElevatedButton(
                onPressed: level < 40
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _startBattleWithEnemy(
                          const EnemyTemplate(id: 'ex_sannin', name: 'Jiraiya (Tryb Mędrca)', maxHp: 1800, baseAtk: 110, baseDef: 65, traits: [BossTrait.ironSkin, BossTrait.chakraLeech, BossTrait.chakraThorns]),
                          isExamFight: true,
                        );
                      },
                child: const Text('Próba Mędrca na Sannina (Wymagany Lvl 40)'),
              ),
            if (currentRank == 'Sannin')
              const Text('Osiągnąłeś szczyt hierarchii ninja jako Legendarny Sannin!', style: TextStyle(color: Colors.greenAccent)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zamknij', style: TextStyle(color: Colors.amber)),
          )
        ],
      ),
    );
  }

  void _showZoneSelectDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D24),
        title: const Text('Wybierz Obszar Misji'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: zones.length,
            itemBuilder: (context, idx) {
              final z = zones[idx];
              final cp = zoneCheckpoints[z.id] ?? 0;
              final isUnlocked = level >= z.minLevel;
              return ListTile(
                title: Text(z.name, style: TextStyle(color: isUnlocked ? Colors.white : Colors.grey)),
                subtitle: Text('Wymagany Lvl: ${z.minLevel} | Odblokowany Posterunek: $cp'),
                trailing: isUnlocked
                    ? ElevatedButton(
                        onPressed: () {
                          setState(() {
                            currentZoneId = z.id;
                            currentZoneDepth = cp;
                            adventureLogs.insert(0, '🗺️ Wyruszasz do strefy: ${z.name} (Zaczynasz od głębokości $cp).');
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Wybierz'),
                      )
                    : const Icon(Icons.lock, color: Colors.grey),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zamknij', style: TextStyle(color: Colors.amber)),
          )
        ],
      ),
    );
  }

  Color _getRarityColor(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:
        return Colors.white;
      case ItemRarity.rare:
        return Colors.blueAccent;
      case ItemRarity.epic:
        return Colors.purpleAccent;
      case ItemRarity.legendary:
        return Colors.amberAccent;
    }
  }

  String _statLabelForSlot(GearSlot slot) {
    switch (slot) {
      case GearSlot.weapon:
      case GearSlot.helmet:
        return 'Atak';
      case GearSlot.armor:
      case GearSlot.boots:
        return 'Obrona';
      case GearSlot.trinket:
        return 'Moc Jutsu';
    }
  }

  MainAxisSize get minAxisSize => MainAxisSize.min;

  Widget _beltTile(String title, String desc, String bonus, bool isUnlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isUnlocked ? const Color(0xFF1B3B2B) : Colors.black38,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isUnlocked ? Colors.greenAccent : Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isUnlocked ? Colors.white : Colors.grey)),
                Text(desc, style: const TextStyle(fontSize: 10, color: Colors.white60)),
              ],
            ),
          ),
          Text(bonus, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isUnlocked ? Colors.greenAccent : Colors.grey)),
        ],
      ),
    );
  }

  Widget _milestoneProgressTile(String name, String stat, String currentBonus) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(stat, style: const TextStyle(fontSize: 11, color: Colors.white54)),
            ],
          ),
          Text(currentBonus, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _itemCardExpanded(String label, EquipmentItem item, String statText) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1E26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text(statText, style: const TextStyle(fontSize: 10, color: Colors.amber)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeroPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF15181F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _itemCardExpanded('Broń', currentWeapon, 'Atak: +${currentWeapon.effectiveStat}'),
              const SizedBox(width: 6),
              _itemCardExpanded('Pancerz', currentArmor, 'Obrona: +${currentArmor.effectiveStat}'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _itemCardExpanded('Głowa', currentHelmet, 'Atak: +${currentHelmet.effectiveStat}'),
              const SizedBox(width: 6),
              _itemCardExpanded('Buty', currentBoots, 'Obrona: +${currentBoots.effectiveStat}'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _itemCardExpanded('Talizman', currentTrinket, 'Moc Jutsu: +${currentTrinket.effectiveStat}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVillageGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.1,
      children: [
        _menuTile('🎖️ Kamienie Milowe', 'Pasy i stałe premie', _showMilestonesDialog),
        _menuTile('📜 Bingo Book', 'Księga Gończych', _showBingoBookDialog),
        _menuTile('🎒 Plecak Ekwipunku', '${inventory.length} przedmiotów', _showInventoryDialog),
        _menuTile('🔨 Kowal Konohy', 'Ulepszanie rynsztunku', _showBlacksmithDialog),
        _menuTile('⛩️ Egzaminy Ninja', 'Awanse w randze', _showExamDialog),
        _menuTile('🗺️ Wybór Strefy', zones.firstWhere((z) => z.id == currentZoneId).name, _showZoneSelectDialog),
        _menuTile('🏥 Szpital Konohy', 'Pełne leczenie (15 Ryo)', () {
          setState(() {
            if (ryo >= 15) {
              ryo -= 15;
              hp = maxHp;
              chakra = maxChakra;
              adventureLogs.insert(0, '🏥 Zostałeś w pełni uleczony w Szpitalu Konohy.');
              _saveGameData();
            }
          });
        }),
      ],
    );
  }

  Widget _menuTile(String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C202A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.white54), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shinobi Lootr - $currentRank (Lvl $level)'),
        backgroundColor: const Color(0xFF15181F),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('💰 $ryo Ryo', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildTopHeroPanel(),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF15181F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('❤️ HP: $hp / $maxHp', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  Text('🌀 CP: $chakra / ${maxChakra + milestoneBonusMaxCp}', style: const TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold)),
                  Text('🗡️ Atk: $totalAttack', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                  Text('🛡️ Def: $totalDefense', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                  Text('✨ +$totalJutsuPower%', style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildVillageGrid(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _stepForwardInZone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.explore),
                    label: Text('Idź w głąb strefy (Głębokość: $currentZoneDepth)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 160,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF15181F),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: ListView.builder(
                itemCount: adventureLogs.length,
                itemBuilder: (context, idx) => Text(
                  adventureLogs[idx],
                  style: const TextStyle(fontSize: 12, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
