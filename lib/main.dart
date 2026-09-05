import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const ShinobiLooterApp());

enum ItemRarity { common, rare, epic, legendary }
enum ConsumableType { healHp, healChakra, buffAtk, maxStats, directDmg, smokeEscape, fullRestore }
enum GearSlot { weapon, armor, helmet, boots, trinket }
enum JutsuEffect { none, burn, freeze, stun, lifesteal, shock }
enum EnemyPrefix { weak, normal, strong }

const String matIronOre = 'mat_iron_ore';
const String matSteel = 'mat_steel';
const String matCrystal = 'mat_crystal';
const String matDungeonKey = 'mat_dungeon_key';

class CraftingMaterialInfo {
  final String id;
  final String name;
  final String icon;
  final String desc;

  const CraftingMaterialInfo({
    required this.id,
    required this.name,
    required this.icon,
    required this.desc,
  });
}

const Map<String, CraftingMaterialInfo> craftingMaterials = {
  matIronOre: CraftingMaterialInfo(id: matIronOre, name: 'Ruda Żelaza Czakry', icon: '🪨', desc: 'Ruda do kucia rynsztunku (+1 do +3).'),
  matSteel: CraftingMaterialInfo(id: matSteel, name: 'Sztaba Tamahagane', icon: '🧱', desc: 'Wzmocniona stal (+4 do +6).'),
  matCrystal: CraftingMaterialInfo(id: matCrystal, name: 'Kryształ Esencji Czakry', icon: '💎', desc: 'Mityczny minerał mistrzowskiego kucia (+7 do +9).'),
  matDungeonKey: CraftingMaterialInfo(id: matDungeonKey, name: 'Klucz do Lochów', icon: '🗝️', desc: 'Pozwala na wejście do legendarnych lochów.'),
};

class ShinobiLocation {
  final String id;
  final String name;
  final int minLevel;
  final String description;
  final String icon;

  const ShinobiLocation({
    required this.id,
    required this.name,
    required this.minLevel,
    required this.description,
    required this.icon,
  });
}

const List<ShinobiLocation> shinobiLocations = [
  ShinobiLocation(id: 'loc_gate', name: 'Brama Konohagakure', minLevel: 1, description: 'Bezpieczne obrzeża i lasy wokół Wioski Liścia.', icon: '⛩️'),
  ShinobiLocation(id: 'loc_forest', name: 'Las Śmierci (Strefa 44)', minLevel: 8, description: 'Niebezpieczny poligon treningowy pełny bestii i dzikich shinobi.', icon: '🌲'),
  ShinobiLocation(id: 'loc_waves', name: 'Kraj Fali / Most Tenkū', minLevel: 18, description: 'Tereny walk z bandytami z mgły i najemnikami.', icon: '🌊'),
  ShinobiLocation(id: 'loc_valley', name: 'Dolina Końca', minLevel: 30, description: 'Legendarne miejsce pojedynków o potężnej koncentracji czakry.', icon: '⚡'),
  ShinobiLocation(id: 'loc_akatsuki', name: 'Kryjówka Akatsuki', minLevel: 45, description: 'Elitarna strefa z najgroźniejszymi celami wrogich nacji.', icon: '☁️'),
];

class DungeonBossTemplate {
  final String id;
  final String name;
  final String title;
  final int minLevel;
  final int baseHp;
  final int baseAtk;
  final String icon;

  const DungeonBossTemplate({
    required this.id,
    required this.name,
    required this.title,
    required this.minLevel,
    required this.baseHp,
    required this.baseAtk,
    required this.icon,
  });
}

const List<DungeonBossTemplate> dungeonBossesPool = [
  DungeonBossTemplate(id: 'db_nine_tails', name: 'Demon Kurama (Sześć Ogonów)', title: 'Gniew Kyūbi', minLevel: 12, baseHp: 220, baseAtk: 25, icon: '🦊'),
  DungeonBossTemplate(id: 'db_susanoo_madara', name: 'Perfekcyjne Susanoo (Madara)', title: 'Boski Awatar Zniszczenia', minLevel: 25, baseHp: 380, baseAtk: 38, icon: '🛡️'),
  DungeonBossTemplate(id: 'db_kaguya_god', name: 'Kaguya Ōtsutsuki (Bóg Królika)', title: 'Matka Czakry i Wymiarów', minLevel: 40, baseHp: 550, baseAtk: 50, icon: '🌕'),
];

class BaseGearArchetype {
  final String baseName;
  final GearSlot slot;
  final int baseStat;
  final String setGroup;
  final String lore;

  const BaseGearArchetype({
    required this.baseName,
    required this.slot,
    required this.baseStat,
    this.setGroup = 'none',
    required this.lore,
  });
}

const List<BaseGearArchetype> standardArchetypesPool = [
  BaseGearArchetype(slot: GearSlot.weapon, baseName: 'Standardowy Kunai', baseStat: 4, lore: 'Podstawowe narzędzie każdego ninja.'),
  BaseGearArchetype(slot: GearSlot.weapon, baseName: 'Składany Shuriken Fūma', baseStat: 6, lore: 'Wirujące ostrza.'),
  BaseGearArchetype(slot: GearSlot.weapon, baseName: 'Krótki Miecz Tanto ANBU', baseStat: 8, setGroup: 'anbu', lore: 'Ostrze skrytobójców z Korzenia.'),
  BaseGearArchetype(slot: GearSlot.weapon, baseName: 'Bliźniacze Tasaki Kiri', baseStat: 9, lore: 'Agresywny oręż sieczny z Mgły.'),
  BaseGearArchetype(slot: GearSlot.weapon, baseName: 'Krótki Miecz Chidorigatana', baseStat: 12, lore: 'Ostrze idealnie przewodzące błyskawice.'),
  BaseGearArchetype(slot: GearSlot.armor, baseName: 'Szata Treningowa Genina', baseStat: 3, lore: 'Lekki płócienny strój.'),
  BaseGearArchetype(slot: GearSlot.armor, baseName: 'Kamizelka Jonina Konohy', baseStat: 9, lore: 'Oficjalny pancerz taktyczny.'),
  BaseGearArchetype(slot: GearSlot.armor, baseName: 'Szata Pustelnika Myōboku', baseStat: 13, setGroup: 'myoboku', lore: 'Szata nasycona energią senjutsu.'),
  BaseGearArchetype(slot: GearSlot.helmet, baseName: 'Ochraniacz Czołowy Protektor', baseStat: 2, lore: 'Metalowa płytka z symbolem wioski.'),
  BaseGearArchetype(slot: GearSlot.helmet, baseName: 'Porcelanowa Maska Lisa ANBU', baseStat: 6, setGroup: 'anbu', lore: 'Zaciera tożsamość i aurę czakry.'),
  BaseGearArchetype(slot: GearSlot.boots, baseName: 'Standardowe Sandały Shinobi', baseStat: 2, lore: 'Dobre oparcie stóp na drzewach.'),
  BaseGearArchetype(slot: GearSlot.boots, baseName: 'Drewniane Geta Żabiego Mędrca', baseStat: 9, setGroup: 'myoboku', lore: 'Idealny balans na śliskich skałach.'),
  BaseGearArchetype(slot: GearSlot.trinket, baseName: 'Amulet Ochronny z Liścia', baseStat: 3, lore: 'Błogosławieństwo kaplicy Konohy.'),
  BaseGearArchetype(slot: GearSlot.trinket, baseName: 'Pieczęć Skupienia Czakry', baseStat: 8, lore: 'Zmniejsza straty energii przy jutsu.'),
];

class LegendaryGearTemplate {
  final String name;
  final GearSlot slot;
  final int baseStat;
  final String bonusEffect;
  final int bonusValue;
  final String setGroup;
  final String lore;

  const LegendaryGearTemplate({
    required this.name,
    required this.slot,
    required this.baseStat,
    required this.bonusEffect,
    required this.bonusValue,
    this.setGroup = 'none',
    required this.lore,
  });
}

const List<LegendaryGearTemplate> legendaryArtifactsPool = [
  LegendaryGearTemplate(name: 'Miecz Totsuka (Sakegari)', slot: GearSlot.weapon, baseStat: 36, bonusEffect: 'Pieczęć Wiecznego Snu', bonusValue: 8, lore: 'Widmowe ostrze pieczętujące w tykwie.'),
  LegendaryGearTemplate(name: 'Samehada (Żarłacz Kisame)', slot: GearSlot.weapon, baseStat: 34, bonusEffect: 'Pożeranie Czakry', bonusValue: 8, lore: 'Żywy miecz wysysający energię wroga.'),
  LegendaryGearTemplate(name: 'Pancerz Ostatecznego Susanoo', slot: GearSlot.armor, baseStat: 38, bonusEffect: 'Bóstwo Zniszczenia', bonusValue: 10, lore: 'Skrzydlata zbroja niszcząca pasma górskie.'),
  LegendaryGearTemplate(name: 'Korona Rogatej Bogini Kaguya', slot: GearSlot.helmet, baseStat: 32, bonusEffect: 'Wizja Byakugana', bonusValue: 8, lore: 'Boski relikt Świętego Drzewa.'),
  LegendaryGearTemplate(name: 'Naszyjnik Pierwszego Hokage', slot: GearSlot.trinket, baseStat: 25, bonusEffect: 'Ocalenie Duszy Hashiramy', bonusValue: 10, lore: 'Kryształ czakry chroniący przed natychmiastowym zgonem.'),
];

class NinjaGear {
  final String name;
  final ItemRarity rarity;
  final int baseStat;
  final String bonusEffect;
  final int bonusValue;
  final String setGroup;
  final bool isSoulbound;
  final int upgradeLevel;

  const NinjaGear({
    required this.name,
    required this.rarity,
    required this.baseStat,
    required this.bonusEffect,
    required this.bonusValue,
    this.setGroup = 'none',
    this.isSoulbound = false,
    this.upgradeLevel = 0,
  });

  NinjaGear copyWith({
    String? name,
    ItemRarity? rarity,
    int? baseStat,
    String? bonusEffect,
    int? bonusValue,
    String? setGroup,
    bool? isSoulbound,
    int? upgradeLevel,
  }) {
    return NinjaGear(
      name: name ?? this.name,
      rarity: rarity ?? this.rarity,
      baseStat: baseStat ?? this.baseStat,
      bonusEffect: bonusEffect ?? this.bonusEffect,
      bonusValue: bonusValue ?? this.bonusValue,
      setGroup: setGroup ?? this.setGroup,
      isSoulbound: isSoulbound ?? this.isSoulbound,
      upgradeLevel: upgradeLevel ?? this.upgradeLevel,
    );
  }

  int get effectiveStat => baseStat + (upgradeLevel * (2 + rarity.index));
  String get displayName => upgradeLevel > 0 ? '$name +$upgradeLevel' : name;

  Map<String, dynamic> toJson() => {
        'name': name,
        'rarity': rarity.index,
        'baseStat': baseStat,
        'bonusEffect': bonusEffect,
        'bonusValue': bonusValue,
        'setGroup': setGroup,
        'isSoulbound': isSoulbound,
        'upgradeLevel': upgradeLevel,
      };

  factory NinjaGear.fromJson(Map<String, dynamic> json) => NinjaGear(
        name: json['name'],
        rarity: ItemRarity.values[json['rarity']],
        baseStat: json['baseStat'],
        bonusEffect: json['bonusEffect'] ?? 'Brak',
        bonusValue: json['bonusValue'] ?? 0,
        setGroup: json['setGroup'] ?? 'none',
        isSoulbound: json['isSoulbound'] ?? false,
        upgradeLevel: json['upgradeLevel'] ?? 0,
      );

  Color get color {
    switch (rarity) {
      case ItemRarity.common: return const Color(0xFFCFD8DC);
      case ItemRarity.rare: return const Color(0xFF29B6F6);
      case ItemRarity.epic: return const Color(0xFFBA68C8);
      case ItemRarity.legendary: return const Color(0xFFFFD54F);
    }
  }

  String get rarityLabel {
    switch (rarity) {
      case ItemRarity.common: return 'Zwykły';
      case ItemRarity.rare: return 'Mistrzowski';
      case ItemRarity.epic: return 'Pradawny';
      case ItemRarity.legendary: return 'Legendarny';
    }
  }
}

class Consumable {
  final String id;
  final String name;
  final String description;
  final String statBonusText;
  final ConsumableType type;
  final int value;
  final int price;
  final String icon;

  const Consumable({
    required this.id,
    required this.name,
    required this.description,
    required this.statBonusText,
    required this.type,
    required this.value,
    required this.price,
    required this.icon,
  });
}

const List<Consumable> allConsumables = [
  Consumable(id: 'c_pill', name: 'Pigułka Żywnościowa', description: 'Błyskawicznie nasyca obieg czakry.', statBonusText: '🌀 +35 CP', type: ConsumableType.healChakra, value: 35, price: 35, icon: '💊'),
  Consumable(id: 'c_dango', name: 'Słodkie Dango', description: 'Przekąska przywracająca siły.', statBonusText: '❤️ +20 HP', type: ConsumableType.healHp, value: 20, price: 25, icon: '🍡'),
  Consumable(id: 'c_bandage', name: 'Bandaże Uciskowe', description: 'Zatamowują rany cięte.', statBonusText: '❤️ +30 HP', type: ConsumableType.healHp, value: 30, price: 38, icon: '🩹'),
  Consumable(id: 'c_ramen', name: 'Ramen Ichiraku', description: 'Legendarne danie odnawiające siły.', statBonusText: '❤️/🌀 Max +10 & Full', type: ConsumableType.fullRestore, value: 10, price: 180, icon: '🍜'),
  Consumable(id: 'c_power_pill', name: 'Pigułka Siły', description: 'Wzmacnia siłę ciosów.', statBonusText: '⚔️ +3 Ataku', type: ConsumableType.buffAtk, value: 3, price: 140, icon: '⚡'),
  Consumable(id: 'c_kibaku', name: 'Pieczęć Wybuchowa', description: 'Zadaje bezpośrednie obrażenia bojowe.', statBonusText: '💥 30 DMG', type: ConsumableType.directDmg, value: 30, price: 60, icon: '🏷️'),
  Consumable(id: 'c_smoke', name: 'Bomba Dymna', description: 'Tworzy gęstą zasłonę do odwrotu.', statBonusText: '💨 Ucieczka 100%', type: ConsumableType.smokeEscape, value: 0, price: 45, icon: '💨'),
];

class Jutsu {
  final String id;
  final String name;
  final int chakraCost;
  final int powerMultiplier;
  final int costRyo;
  final Color color;
  final JutsuEffect effect;
  final int effectDuration;
  final int effectValue;

  const Jutsu({
    required this.id,
    required this.name,
    required this.chakraCost,
    required this.powerMultiplier,
    required this.costRyo,
    required this.color,
    this.effect = JutsuEffect.none,
    this.effectDuration = 0,
    this.effectValue = 0,
  });

  String get effectDescription {
    switch (effect) {
      case JutsuEffect.burn: return 'Podpalenie: $effectValue dmg/turę ($effectDuration tury)';
      case JutsuEffect.freeze: return 'Zamrożenie: Unieruchamia wroga na $effectDuration turę';
      case JutsuEffect.stun: return 'Ogłuszenie: Wróg traci $effectDuration turę';
      case JutsuEffect.lifesteal: return 'Wyssanie: Leczy HP o $effectValue% obrażeń';
      case JutsuEffect.shock: return 'Paraliż: 50% szansy na utratę tury przez wroga';
      case JutsuEffect.none: return 'Czyste obrażenia fizyczne/czakry';
    }
  }
}

const List<Jutsu> allJutsuPool = [
  Jutsu(id: 'j_taijutsu', name: 'Podstawowe Taijutsu', chakraCost: 0, powerMultiplier: 1, costRyo: 0, color: Color(0xFF78909C)),
  Jutsu(id: 'j_konoha_senpuu', name: 'Konoha Senpū', chakraCost: 10, powerMultiplier: 2, costRyo: 180, color: Color(0xFF66BB6A), effect: JutsuEffect.stun, effectDuration: 1),
  Jutsu(id: 'j_katon', name: 'Katon: Goukakyu', chakraCost: 16, powerMultiplier: 2, costRyo: 260, color: Color(0xFFFF7043), effect: JutsuEffect.burn, effectDuration: 2, effectValue: 6),
  Jutsu(id: 'j_rasengan', name: 'Rasengan', chakraCost: 32, powerMultiplier: 3, costRyo: 650, color: Color(0xFF42A5F5)),
  Jutsu(id: 'j_amaterasu', name: 'Amaterasu', chakraCost: 55, powerMultiplier: 5, costRyo: 1800, color: Color(0xFF7E57C2), effect: JutsuEffect.burn, effectDuration: 4, effectValue: 20),
];

class EnemyTemplate {
  final String name;
  final String title;
  final int baseHp;
  final int baseAtk;
  final bool isBoss;

  const EnemyTemplate({
    required this.name,
    required this.title,
    required this.baseHp,
    required this.baseAtk,
    this.isBoss = false,
  });
}

const List<EnemyTemplate> standardEnemiesPool = [
  EnemyTemplate(name: 'Dziki Ninja-Pies', title: 'Zdziczały Ninken', baseHp: 22, baseAtk: 6),
  EnemyTemplate(name: 'Bandyta z Kraju Fal', title: 'Pospolity Rabuś', baseHp: 26, baseAtk: 7),
  EnemyTemplate(name: 'Zbuntowany Ninja Deszczu', title: 'Nuke-nin z Amegakure', baseHp: 32, baseAtk: 8),
  EnemyTemplate(name: 'Szpieg z Iwagakure', title: 'Zwiadowca Skały', baseHp: 36, baseAtk: 9),
  EnemyTemplate(name: 'Klon Białego Zetsu', title: 'Infiltrator Mokuton', baseHp: 40, baseAtk: 10),
];

const List<EnemyTemplate> bossesPool = [
  EnemyTemplate(name: 'Zabuza Momochi', title: 'Demon Ukrytej Mgły', baseHp: 95, baseAtk: 16, isBoss: true),
  EnemyTemplate(name: 'Gaara Pustyni', title: 'Głos Shukaku', baseHp: 120, baseAtk: 19, isBoss: true),
  EnemyTemplate(name: 'Itachi Uchiha', title: 'Mistrz Mangekyō Sharingana', baseHp: 150, baseAtk: 25, isBoss: true),
];

const NinjaGear defaultStarterWeapon = NinjaGear(name: 'Podstawowy Kunai', rarity: ItemRarity.common, baseStat: 4, bonusEffect: 'Brak', bonusValue: 0, isSoulbound: true);
const NinjaGear defaultStarterArmor = NinjaGear(name: 'Szata Treningowa Genina', rarity: ItemRarity.common, baseStat: 3, bonusEffect: 'Brak', bonusValue: 0, isSoulbound: true);
const NinjaGear defaultStarterHelmet = NinjaGear(name: 'Ochraniacz Czołowy Protektor', rarity: ItemRarity.common, baseStat: 2, bonusEffect: 'Brak', bonusValue: 0, isSoulbound: true);
const NinjaGear defaultStarterBoots = NinjaGear(name: 'Standardowe Sandały Shinobi', rarity: ItemRarity.common, baseStat: 2, bonusEffect: 'Brak', bonusValue: 0, isSoulbound: true);
const NinjaGear defaultStarterTrinket = NinjaGear(name: 'Amulet Ochronny z Liścia', rarity: ItemRarity.common, baseStat: 2, bonusEffect: 'Brak', bonusValue: 0, isSoulbound: true);

class ShinobiLooterApp extends StatelessWidget {
  const ShinobiLooterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0E0D),
        dialogBackgroundColor: const Color(0xFF181615),
        cardColor: const Color(0xFF1B1917),
      ),
      home: const ShinobiScreen(),
    );
  }
}

class ShinobiScreen extends StatefulWidget {
  const ShinobiScreen({super.key});

  @override
  State<ShinobiScreen> createState() => _ShinobiScreenState();
}

class _ShinobiScreenState extends State<ShinobiScreen> {
  final Random _rng = Random();

  bool inVillage = true;
  String currentSelectedLocationId = 'loc_gate';

  int hp = 100;
  int maxHp = 100;
  int chakra = 80;
  int maxChakra = 80;

  int bonusAtk = 0;
  int ryo = 80;
  int ninjaExp = 0;
  int masteryPoints = 0;
  int passedRankIndex = 0;
  bool isLoading = true;

  int? activeMissionIndex;
  int currentMissionKills = 0;
  Set<String> completedMissionsHistory = {};

  Map<String, int> bag = {'c_pill': 2, 'c_dango': 1, 'c_kibaku': 1, 'c_smoke': 1};
  Map<String, int> sealedBag = {};
  Map<String, int> craftingBag = {matIronOre: 2, matDungeonKey: 1};

  int vitalTrainingCount = 0;
  int dungeonCooldownTimestamp = 0;

  List<Jutsu> equippedJutsu = [allJutsuPool[0]];
  List<Jutsu> knownJutsu = [allJutsuPool[0]];

  NinjaGear currentWeapon = defaultStarterWeapon;
  NinjaGear currentArmor = defaultStarterArmor;
  NinjaGear currentHelmet = defaultStarterHelmet;
  NinjaGear currentBoots = defaultStarterBoots;
  NinjaGear currentTrinket = defaultStarterTrinket;

  final List<String> log = ['Witaj w Konohagakure! Wybierz opcję z menu bazy.'];

  static const int softCapLevel = 50;

  int get level {
    for (int lvl = 1; lvl <= softCapLevel; lvl++) {
      if (ninjaExp < expRequiredForLevel(lvl + 1)) {
        return lvl;
      }
    }
    return softCapLevel;
  }

  static int expRequiredForLevel(int lvl) {
    if (lvl <= 1) return 0;
    return (110 * pow(lvl, 2.05)).floor();
  }

  int get expForNextLevel => level >= softCapLevel ? expRequiredForLevel(softCapLevel) : expRequiredForLevel(level + 1);

  String get ninjaRank {
    switch (passedRankIndex) {
      case 5: return 'Legendarny Sannin / Kage';
      case 4: return 'Jōnin Bojowy';
      case 3: return 'Tokubetsu Jōnin';
      case 2: return 'Chūnin';
      case 1: return 'Genin';
      default: return 'Nowicjusz Akademii';
    }
  }

  Color get rankColor {
    switch (passedRankIndex) {
      case 5: return const Color(0xFFFFD54F);
      case 4: return const Color(0xFFFF5252);
      case 3: return const Color(0xFFBA68C8);
      case 2: return const Color(0xFF448AFF);
      case 1: return const Color(0xFF69F0AE);
      default: return const Color(0xFF90A4AE);
    }
  }

  int get totalAttack => currentWeapon.effectiveStat + currentWeapon.bonusValue + currentTrinket.effectiveStat + bonusAtk + (level * 2);
  int get totalDefense => currentArmor.effectiveStat + currentArmor.bonusValue + currentHelmet.effectiveStat + currentHelmet.bonusValue + currentBoots.effectiveStat + currentBoots.bonusValue;

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hp = prefs.getInt('hp') ?? 100;
      maxHp = prefs.getInt('maxHp') ?? 100;
      chakra = prefs.getInt('chakra') ?? 80;
      maxChakra = prefs.getInt('maxChakra') ?? 80;
      bonusAtk = prefs.getInt('bonusAtk') ?? 0;
      ryo = prefs.getInt('ryo') ?? 80;
      ninjaExp = prefs.getInt('ninjaExp') ?? 0;
      masteryPoints = prefs.getInt('masteryPoints') ?? 0;
      passedRankIndex = prefs.getInt('passedRankIndex') ?? 0;
      inVillage = prefs.getBool('inVillage') ?? true;
      currentSelectedLocationId = prefs.getString('currentSelectedLocationId') ?? 'loc_gate';
      activeMissionIndex = prefs.getInt('activeMissionIndex');
      currentMissionKills = prefs.getInt('currentMissionKills') ?? 0;
      vitalTrainingCount = prefs.getInt('vitalTrainingCount') ?? 0;
      dungeonCooldownTimestamp = prefs.getInt('dungeonCooldownTimestamp') ?? 0;

      final bagJson = prefs.getString('ninjaBag');
      if (bagJson != null) bag = Map<String, int>.from(jsonDecode(bagJson));

      final sealedBagJson = prefs.getString('sealedBag');
      if (sealedBagJson != null) sealedBag = Map<String, int>.from(jsonDecode(sealedBagJson));

      final craftJson = prefs.getString('craftingBag');
      if (craftJson != null) craftingBag = Map<String, int>.from(jsonDecode(craftJson));

      final weaponStr = prefs.getString('currentWeapon');
      if (weaponStr != null) currentWeapon = NinjaGear.fromJson(jsonDecode(weaponStr));

      final armorStr = prefs.getString('currentArmor');
      if (armorStr != null) currentArmor = NinjaGear.fromJson(jsonDecode(armorStr));

      final helmetStr = prefs.getString('currentHelmet');
      if (helmetStr != null) currentHelmet = NinjaGear.fromJson(jsonDecode(helmetStr));

      final bootsStr = prefs.getString('currentBoots');
      if (bootsStr != null) currentBoots = NinjaGear.fromJson(jsonDecode(bootsStr));

      final trinketStr = prefs.getString('currentTrinket');
      if (trinketStr != null) currentTrinket = NinjaGear.fromJson(jsonDecode(trinketStr));

      final knownIds = prefs.getStringList('knownJutsuIds');
      if (knownIds != null && knownIds.isNotEmpty) {
        knownJutsu = allJutsuPool.where((j) => knownIds.contains(j.id)).toList();
      }

      final equippedIds = prefs.getStringList('equippedJutsuIds');
      if (equippedIds != null && equippedIds.isNotEmpty) {
        equippedJutsu = allJutsuPool.where((j) => equippedIds.contains(j.id)).toList();
      }
      isLoading = false;
    });
  }

  Future<void> _saveGameData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hp', hp);
    await prefs.setInt('maxHp', maxHp);
    await prefs.setInt('chakra', chakra);
    await prefs.setInt('maxChakra', maxChakra);
    await prefs.setInt('bonusAtk', bonusAtk);
    await prefs.setInt('ryo', ryo);
    await prefs.setInt('ninjaExp', ninjaExp);
    await prefs.setInt('masteryPoints', masteryPoints);
    await prefs.setInt('passedRankIndex', passedRankIndex);
    await prefs.setBool('inVillage', inVillage);
    await prefs.setString('currentSelectedLocationId', currentSelectedLocationId);

    if (activeMissionIndex != null) {
      await prefs.setInt('activeMissionIndex', activeMissionIndex!);
    } else {
      await prefs.remove('activeMissionIndex');
    }
    await prefs.setInt('currentMissionKills', currentMissionKills);
    await prefs.setInt('vitalTrainingCount', vitalTrainingCount);
    await prefs.setInt('dungeonCooldownTimestamp', dungeonCooldownTimestamp);
    await prefs.setString('ninjaBag', jsonEncode(bag));
    await prefs.setString('sealedBag', jsonEncode(sealedBag));
    await prefs.setString('craftingBag', jsonEncode(craftingBag));
    await prefs.setString('currentWeapon', jsonEncode(currentWeapon.toJson()));
    await prefs.setString('currentArmor', jsonEncode(currentArmor.toJson()));
    await prefs.setString('currentHelmet', jsonEncode(currentHelmet.toJson()));
    await prefs.setString('currentBoots', jsonEncode(currentBoots.toJson()));
    await prefs.setString('currentTrinket', jsonEncode(currentTrinket.toJson()));
    await prefs.setStringList('knownJutsuIds', knownJutsu.map((j) => j.id).toList());
    await prefs.setStringList('equippedJutsuIds', equippedJutsu.map((j) => j.id).toList());
  }

  void addExperience(int amount) {
    final int oldLvl = level;
    ninjaExp += amount;
    if (level > oldLvl) {
      addLog('⚡ AWANS! Osiągnięto Poziom $level!');
    }
    _saveGameData();
  }

  void addLog(String text) {
    setState(() {
      log.insert(0, text);
      if (log.length > 40) log.removeLast();
    });
    _saveGameData();
  }

  void returnToVillage({bool fallenInBattle = false}) {
    setState(() {
      inVillage = true;
      hp = maxHp;
      chakra = maxChakra;
      bag.clear();
    });

    if (fallenInBattle) {
      addLog('💀 Porażka w terenie! Medyk odratował Twoje życie.');
    } else {
      addLog('⛩️ Bezpieczny powrót do Konohy.');
    }
    _saveGameData();
  }

  void leaveVillage(ShinobiLocation location) {
    if (level < location.minLevel) {
      addLog('⚠️ Wymagany ${location.minLevel} poziom, aby wejść do lokacji: ${location.name}!');
      return;
    }
    setState(() {
      inVillage = false;
      currentSelectedLocationId = location.id;
    });
    addLog('🍃 Wyruszasz do lokacji: ${location.name}!');
    _saveGameData();
  }

  void addConsumableToBag(String id, [int count = 1]) {
    bag[id] = (bag[id] ?? 0) + count;
    _saveGameData();
  }

  void addCraftingMaterial(String matId, [int count = 1]) {
    craftingBag[matId] = (craftingBag[matId] ?? 0) + count;
    _saveGameData();
  }

  bool useConsumable(Consumable item) {
    bool fromUnsealed = (bag[item.id] ?? 0) > 0;
    if (!fromUnsealed) return false;

    setState(() {
      bag[item.id] = bag[item.id]! - 1;
      if (bag[item.id] == 0) bag.remove(item.id);

      switch (item.type) {
        case ConsumableType.healHp:
          hp = min(maxHp, hp + item.value);
          addLog('${item.icon} Użyto [${item.name}]: +${item.value} HP.');
          break;
        case ConsumableType.healChakra:
          chakra = min(maxChakra, chakra + item.value);
          addLog('${item.icon} Użyto [${item.name}]: +${item.value} CP.');
          break;
        case ConsumableType.fullRestore:
          maxHp += item.value;
          maxChakra += item.value;
          hp = maxHp;
          chakra = maxChakra;
          addLog('${item.icon} Pełna regeneracja!');
          break;
        case ConsumableType.buffAtk:
          bonusAtk += item.value;
          addLog('${item.icon} Zwiększono atak o ${item.value}.');
          break;
        default:
          break;
      }
    });
    _saveGameData();
    return true;
  }

  void proceedExploration() {
    if (hp <= 0) return;

    final loc = shinobiLocations.firstWhere((l) => l.id == currentSelectedLocationId);
    final roll = _rng.nextInt(100);

    if (roll < 25) {
      addLog('🌿 ${loc.name}: Spokojna okolica. Nikogo tu nie spotkałeś.');
    } else if (roll < 62) {
      final enemy = standardEnemiesPool[_rng.nextInt(standardEnemiesPool.length)];
      _startBattleWithEnemy(enemy);
    } else if (roll < 80) {
      final boss = bossesPool[_rng.nextInt(bossesPool.length)];
      _startBattleWithEnemy(boss);
    } else if (roll < 92) {
      _findLoot();
    } else {
      addCraftingMaterial(matDungeonKey, 1);
      addLog('🗝️ Sukces zwiadu! Znaleziono rzadki Klucz do Lochów!');
    }
  }

  void _openMedicDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setMedicState) {
          final int vitalCost = 180 + (vitalTrainingCount * 45);

          return AlertDialog(
            backgroundColor: const Color(0xFF102018),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF66BB6A), width: 1.2)),
            title: const Row(
              children: [
                Text('🩺 ', style: TextStyle(fontSize: 22)),
                Expanded(child: Text('Szpital Konohy (Medyk)', style: TextStyle(color: Color(0xFFA5D6A7), fontWeight: FontWeight.bold))),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Text('💚', style: TextStyle(fontSize: 24)),
                      title: const Text('Pełne Leczenie', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Odnawia HP i CP do 100%', style: TextStyle(fontSize: 10, color: Colors.white60)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00695C)),
                        onPressed: (hp < maxHp || chakra < maxChakra) && ryo >= 25
                            ? () {
                                setState(() {
                                  ryo -= 25;
                                  hp = maxHp;
                                  chakra = maxChakra;
                                });
                                _saveGameData();
                                setMedicState(() {});
                                addLog('🩺 Opatrzono rany (-25 Ryo).');
                              }
                            : null,
                        child: const Text('25 Ryo', style: TextStyle(fontSize: 10)),
                      ),
                    ),
                    const Divider(color: Colors.white12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Text('🧬', style: TextStyle(fontSize: 24)),
                      title: Text('Trening Witalności (#${vitalTrainingCount + 1})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: const Text('+10 Max HP i +10 Max CP', style: TextStyle(fontSize: 10, color: Colors.white60)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                        onPressed: ryo >= vitalCost
                            ? () {
                                setState(() {
                                  ryo -= vitalCost;
                                  vitalTrainingCount++;
                                  maxHp += 10;
                                  maxChakra += 10;
                                  hp += 10;
                                  chakra += 10;
                                });
                                _saveGameData();
                                setMedicState(() {});
                                addLog('✨ Rozwinięto witalność! (-$vitalCost Ryo).');
                              }
                            : null,
                        child: Text('$vitalCost Ryo', style: TextStyle(fontSize: 10)),
                      ),
                    ),
                    const Divider(color: Colors.white12),
                    const Text('Kup zapasy na drogę:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D))),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: allConsumables.map((c) {
                        return ActionChip(
                          avatar: Text(c.icon),
                          label: Text('${c.name} (${c.price} Ryo)', style: const TextStyle(fontSize: 10)),
                          onPressed: ryo >= c.price
                              ? () {
                                  setState(() {
                                    ryo -= c.price;
                                    bag[c.id] = (bag[c.id] ?? 0) + 1;
                                  });
                                  _saveGameData();
                                  setMedicState(() {});
                                  addLog('📦 Zakupiono [${c.name}].');
                                }
                              : null,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Wyjdź', style: TextStyle(color: Colors.grey))),
            ],
          );
        },
      ),
    );
  }

  void _openBlacksmithDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSmithState) {
          final items = [
            {'slot': 'Broń', 'gear': currentWeapon, 'slotEnum': GearSlot.weapon},
            {'slot': 'Pancerz', 'gear': currentArmor, 'slotEnum': GearSlot.armor},
            {'slot': 'Głowa', 'gear': currentHelmet, 'slotEnum': GearSlot.helmet},
            {'slot': 'Buty', 'gear': currentBoots, 'slotEnum': GearSlot.boots},
            {'slot': 'Talizman', 'gear': currentTrinket, 'slotEnum': GearSlot.trinket},
          ];

          return AlertDialog(
            backgroundColor: const Color(0xFF1E1712),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFFF8A65), width: 1.2)),
            title: const Row(
              children: [
                Text('🔨 ', style: TextStyle(fontSize: 22)),
                Expanded(child: Text('Zbrojmistrz Konohy (Kowal)', style: TextStyle(color: Color(0xFFFFAB91), fontWeight: FontWeight.bold))),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('🪨 Ruda: ${craftingBag[matIronOre] ?? 0}', style: const TextStyle(fontSize: 10)),
                        Text('🧱 Stal: ${craftingBag[matSteel] ?? 0}', style: const TextStyle(fontSize: 10)),
                        Text('💎 Kryształ: ${craftingBag[matCrystal] ?? 0}', style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                    const Divider(color: Colors.white12),
                    ...items.map((entry) {
                      final slotLabel = entry['slot'] as String;
                      final gear = entry['gear'] as NinjaGear;
                      final slotEnum = entry['slotEnum'] as GearSlot;

                      final int curLvl = gear.upgradeLevel;
                      final bool isMax = curLvl >= 9;

                      String neededMatId = matIronOre;
                      int neededMatCount = 1 + (curLvl ~/ 2);
                      int ryoCost = 70 + (curLvl * 50);

                      if (curLvl >= 6) {
                        neededMatId = matCrystal;
                      } else if (curLvl >= 3) {
                        neededMatId = matSteel;
                      }

                      final matInfo = craftingMaterials[neededMatId]!;
                      final bool hasMats = (craftingBag[neededMatId] ?? 0) >= neededMatCount;
                      final bool canUpgrade = !isMax && ryo >= ryoCost && hasMats;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141211),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: gear.color.withAlpha(90)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$slotLabel: ${gear.displayName}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: gear.color)),
                                Text('Moc: +${gear.effectiveStat}', style: const TextStyle(fontSize: 10, color: Color(0xFF69F0AE))),
                              ],
                            ),
                            const SizedBox(height: 2),
                            if (isMax)
                              const Text('Maksymalny poziom kuźniczy (+9)!', style: TextStyle(color: Color(0xFFFFD54F), fontSize: 10))
                            else ...[
                              Text('Wymaga: ${matInfo.icon} $neededMatCount ${matInfo.name} oraz $ryoCost Ryo', style: const TextStyle(fontSize: 9, color: Colors.white60)),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                                  onPressed: canUpgrade
                                      ? () {
                                          setState(() {
                                            ryo -= ryoCost;
                                            craftingBag[neededMatId] = craftingBag[neededMatId]! - neededMatCount;
                                            int successRate = curLvl < 3 ? 95 : (curLvl < 6 ? 75 : 55);
                                            bool success = _rng.nextInt(100) < successRate;

                                            NinjaGear upgraded = success ? gear.copyWith(upgradeLevel: curLvl + 1) : gear;
                                            if (success) {
                                              addLog('🔨 Sukces kucia! ${gear.name} na +${curLvl + 1}!');
                                            } else {
                                              addLog('⚠️ Kucie nie powiodło się.');
                                            }

                                            switch (slotEnum) {
                                              case GearSlot.weapon: currentWeapon = upgraded; break;
                                              case GearSlot.armor: currentArmor = upgraded; break;
                                              case GearSlot.helmet: currentHelmet = upgraded; break;
                                              case GearSlot.boots: currentBoots = upgraded; break;
                                              case GearSlot.trinket: currentTrinket = upgraded; break;
                                            }
                                          });
                                          _saveGameData();
                                          setSmithState(() {});
                                        }
                                      : null,
                                  child: Text('Kuj na +${curLvl + 1}', style: const TextStyle(fontSize: 10)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Odejdź', style: TextStyle(color: Colors.grey))),
            ],
          );
        },
      ),
    );
  }

  void _openScrollsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setScrollsState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF141920),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF42A5F5), width: 1.2)),
            title: const Text('📜 Zwoje Technik (Max 3 aktywne)', style: TextStyle(color: Color(0xFF80D8FF), fontSize: 15, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: allJutsuPool.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                itemBuilder: (context, index) {
                  final jutsu = allJutsuPool[index];
                  final bool isKnown = knownJutsu.any((j) => j.id == jutsu.id);
                  final bool isEquipped = equippedJutsu.any((j) => j.id == jutsu.id);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(jutsu.name, style: TextStyle(fontSize: 12, color: jutsu.color, fontWeight: FontWeight.bold)),
                    subtitle: Text('Koszt: ${jutsu.chakraCost} CP | Siła: x${jutsu.powerMultiplier}\n${jutsu.effectDescription}', style: const TextStyle(fontSize: 10, color: Colors.white60)),
                    trailing: isKnown
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: isEquipped ? const Color(0xFF2E7D32) : const Color(0xFF37474F)),
                            onPressed: () {
                              setState(() {
                                if (isEquipped) {
                                  if (equippedJutsu.length > 1) {
                                    equippedJutsu.removeWhere((j) => j.id == jutsu.id);
                                  }
                                } else {
                                  if (equippedJutsu.length >= 3) {
                                    equippedJutsu.removeLast();
                                  }
                                  equippedJutsu.add(jutsu);
                                }
                              });
                              _saveGameData();
                              setScrollsState(() {});
                            },
                            child: Text(isEquipped ? 'Założone' : 'Załóż', style: const TextStyle(fontSize: 10)),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
                            onPressed: ryo >= jutsu.costRyo
                                ? () {
                                    setState(() {
                                      ryo -= jutsu.costRyo;
                                      knownJutsu.add(jutsu);
                                    });
                                    _saveGameData();
                                    setScrollsState(() {});
                                    addLog('📜 Nauczono się techniki: ${jutsu.name}!');
                                  }
                                : null,
                            child: Text('Kup (${jutsu.costRyo})', style: const TextStyle(fontSize: 9)),
                          ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zamknij', style: TextStyle(color: Colors.grey))),
            ],
          );
        },
      ),
    );
  }

  void _openBagDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setBagState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF191716),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFFF8A65), width: 1.2)),
            title: const Text('🎒 Plecak Rajdu', style: TextStyle(color: Color(0xFFFFB74D), fontSize: 16, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Posiadany prowiant i mikstury:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white70)),
                    const SizedBox(height: 4),
                    if (bag.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Brak przedmiotów w plecaku!', style: TextStyle(fontSize: 11, color: Colors.white54)),
                      )
                    else
                      ...bag.entries.map((entry) {
                        final item = allConsumables.firstWhere((c) => c.id == entry.key);
                        final qty = entry.value;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF141211), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                          child: Row(
                            children: [
                              Text(item.icon, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${item.name} (x$qty)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    Text(item.description, style: const TextStyle(fontSize: 9, color: Colors.white60)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00695C), padding: const EdgeInsets.symmetric(horizontal: 8)),
                                onPressed: () {
                                  useConsumable(item);
                                  setBagState(() {});
                                },
                                child: const Text('Użyj', style: TextStyle(fontSize: 10)),
                              ),
                            ],
                          ),
                        );
                      }),
                    const Divider(color: Colors.white12),
                    const Text('Materiały rzemieślnicze:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFFFD54F))),
                    ...craftingMaterials.values.map((mat) {
                      final count = craftingBag[mat.id] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${mat.icon} ${mat.name}', style: const TextStyle(fontSize: 10, color: Colors.white70)),
                            Text('$count szt.', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFFD54F))),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zamknij', style: TextStyle(color: Colors.grey))),
            ],
          );
        },
      ),
    );
  }

  void _openDungeonsDialog() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final inCooldown = now < dungeonCooldownTimestamp;
    final remainingCooldownSec = inCooldown ? ((dungeonCooldownTimestamp - now) ~/ 1000) : 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDungeonState) {
          final keysCount = craftingBag[matDungeonKey] ?? 0;

          return AlertDialog(
            backgroundColor: const Color(0xFF161218),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFAB47BC), width: 1.2)),
            title: const Row(
              children: [
                Text('🏛️ ', style: TextStyle(fontSize: 22)),
                Expanded(child: Text('Legendarne Lochy Wioski', style: TextStyle(color: Color(0xFFCE93D8), fontWeight: FontWeight.bold))),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Posiadane klucze: 🗝️ $keysCount szt.', style: const TextStyle(fontSize: 11, color: Color(0xFFFFD54F))),
                    const SizedBox(height: 6),
                    if (inCooldown)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.red.withAlpha(40), borderRadius: BorderRadius.circular(6)),
                        child: Text('⏳ Czas odnowienia lochów: ${remainingCooldownSec ~/ 60}m ${remainingCooldownSec % 60}s', style: const TextStyle(fontSize: 10, color: Color(0xFFFF5252))),
                      ),
                    const Divider(color: Colors.white12),
                    ...dungeonBossesPool.map((boss) {
                      final bool canEnter = level >= boss.minLevel && keysCount > 0 && !inCooldown;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141211),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.withAlpha(120)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${boss.icon} ${boss.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFF3E5F5))),
                                Text('Lvl ${boss.minLevel}+', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                            Text(boss.title, style: const TextStyle(fontSize: 9, color: Colors.white54)),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B1FA2)),
                                onPressed: canEnter
                                    ? () {
                                        setState(() {
                                          craftingBag[matDungeonKey] = keysCount - 1;
                                          dungeonCooldownTimestamp = DateTime.now().millisecondsSinceEpoch + (3 * 60 * 1000);
                                        });
                                        _saveGameData();
                                        Navigator.pop(ctx);
                                        _startBattleWithEnemy(
                                          EnemyTemplate(name: boss.name, title: boss.title, baseHp: boss.baseHp, baseAtk: boss.baseAtk, isBoss: true),
                                        );
                                      }
                                    : null,
                                child: const Text('Wejdź do Lochu', style: TextStyle(fontSize: 10)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zamknij', style: TextStyle(color: Colors.grey))),
            ],
          );
        },
      ),
    );
  }

  void _startBattleWithEnemy(EnemyTemplate template, {bool isExamFight = false, int? examTargetRank}) {
    int enemyMaxHp = template.baseHp;
    int enemyHp = enemyMaxHp;
    String initialMsg = template.isBoss ? '⚠️ BOSS: Pojawia się ${template.name}!' : 'Do walki staje: ${template.name}!';
    List<String> battleLogHistory = [initialMsg];
    int burnTurns = 0;
    int burnDmg = 0;
    int frozenTurns = 0;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0xFF141211),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setBattleState) {
            void appendBattleLog(String line) {
              battleLogHistory.insert(0, line);
              if (battleLogHistory.length > 8) battleLogHistory.removeLast();
            }

            void enemyTurn() {
              if (enemyHp <= 0) return;
              if (frozenTurns > 0) {
                frozenTurns--;
                appendBattleLog('❄️ ${template.name} jest unieruchomiony!');
                setBattleState(() {});
                return;
              }

              final rawDmg = template.baseAtk + _rng.nextInt(4);
              final dmg = max(2, rawDmg - (totalDefense ~/ 2));

              setState(() {
                hp = max(0, hp - dmg);
              });
              appendBattleLog('${template.name} zadaje Ci $dmg obrażeń.');
              _saveGameData();

              if (hp <= 0) {
                Navigator.pop(ctx);
                returnToVillage(fallenInBattle: true);
              }
            }

            void executeJutsu(Jutsu jutsu) {
              if (chakra < jutsu.chakraCost) {
                appendBattleLog('Brak czakry na ${jutsu.name}!');
                setBattleState(() {});
                return;
              }

              setState(() {
                chakra -= jutsu.chakraCost;
              });

              final dealt = (totalAttack * jutsu.powerMultiplier) + _rng.nextInt(4);
              enemyHp = max(0, enemyHp - dealt);
              appendBattleLog('Użyto ${jutsu.name}! Zadano $dealt obrażeń.');

              if (enemyHp <= 0) {
                Navigator.pop(ctx);
                final rewardRyo = template.isBoss ? 120 : 25;
                final expGained = template.isBoss ? 35 : 10;

                setState(() {
                  ryo += rewardRyo;
                });
                addExperience(expGained);
                addLog('🏆 Zwycięstwo nad ${template.name}! +$rewardRyo Ryo, +$expGained EXP.');
                _findLoot(guaranteedBossDrop: template.isBoss);
              } else {
                enemyTurn();
                setBattleState(() {});
              }
            }

            return Container(
              padding: const EdgeInsets.all(16),
              height: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(template.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFFF5252))),
                      Text('$enemyHp / $enemyMaxHp HP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: enemyHp / enemyMaxHp, color: const Color(0xFFEF5350), backgroundColor: Colors.white12, minHeight: 6),
                  const SizedBox(height: 8),
                  Container(
                    height: 100,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFF0F0E0D), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                    child: ListView.builder(
                      reverse: true,
                      itemCount: battleLogHistory.length,
                      itemBuilder: (context, index) {
                        return Text(battleLogHistory[index], style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFFFFCC80)));
                      },
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: equippedJutsu.map((jutsu) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: jutsu.color.withAlpha(100), padding: const EdgeInsets.symmetric(vertical: 8)),
                            onPressed: () => executeJutsu(jutsu),
                            child: Text(jutsu.name, style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _findLoot({bool guaranteedBossDrop = false}) {
    final slot = GearSlot.values[_rng.nextInt(5)];
    final drop = _generateRandomGear(slot: slot, guaranteedBossDrop: guaranteedBossDrop);
    
    NinjaGear currentGear;
    switch (slot) {
      case GearSlot.weapon: currentGear = currentWeapon; break;
      case GearSlot.armor: currentGear = currentArmor; break;
      case GearSlot.helmet: currentGear = currentHelmet; break;
      case GearSlot.boots: currentGear = currentBoots; break;
      case GearSlot.trinket: currentGear = currentTrinket; break;
    }

    _showEquipDialog(newGear: drop, currentGear: currentGear, slot: slot);
  }

  NinjaGear _generateRandomGear({required GearSlot slot, bool guaranteedBossDrop = false}) {
    ItemRarity rarity = ItemRarity.common;
    if (guaranteedBossDrop) {
      rarity = ItemRarity.rare;
    } else {
      final roll = _rng.nextInt(100);
      if (roll > 82) rarity = ItemRarity.rare;
    }

    final arch = standardArchetypesPool.where((a) => a.slot == slot).toList();
    final chosen = arch[_rng.nextInt(arch.length)];
    String prefix = rarity == ItemRarity.rare ? 'Mistrzowski ' : '';

    return NinjaGear(
      name: '$prefix${chosen.baseName}',
      rarity: rarity,
      baseStat: chosen.baseStat + (rarity.index * 3) + _rng.nextInt(2),
      bonusEffect: rarity != ItemRarity.common ? 'Precyzja' : 'Brak',
      bonusValue: rarity != ItemRarity.common ? 3 : 0,
      setGroup: chosen.setGroup,
    );
  }

  void _showEquipDialog({required NinjaGear newGear, required NinjaGear currentGear, required GearSlot slot}) {
    String slotName = slot == GearSlot.weapon ? 'Broń' : (slot == GearSlot.armor ? 'Pancerz' : (slot == GearSlot.helmet ? 'Głowa' : (slot == GearSlot.boots ? 'Buty' : 'Talizman')));
    int diff = newGear.effectiveStat - currentGear.effectiveStat;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF191716),
        title: Text('Odnaleziono: $slotName!', style: const TextStyle(color: Color(0xFFFFB74D), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF141211), borderRadius: BorderRadius.circular(8), border: Border.all(color: newGear.color)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NOWY: ${newGear.displayName}', style: TextStyle(fontWeight: FontWeight.bold, color: newGear.color)),
                  Text('Moc: +${newGear.effectiveStat} (${diff >= 0 ? "+$diff" : "$diff"})', style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF141211), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('POSIADANY: ${currentGear.displayName}', style: TextStyle(fontWeight: FontWeight.bold, color: currentGear.color)),
                  Text('Moc: +${currentGear.effectiveStat}', style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              addLog('Odrzucono: ${newGear.displayName}.');
            },
            child: const Text('Odrzuć', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
            onPressed: () {
              setState(() {
                switch (slot) {
                  case GearSlot.weapon: currentWeapon = newGear; break;
                  case GearSlot.armor: currentArmor = newGear; break;
                  case GearSlot.helmet: currentHelmet = newGear; break;
                  case GearSlot.boots: currentBoots = newGear; break;
                  case GearSlot.trinket: currentTrinket = newGear; break;
                }
              });
              _saveGameData();
              Navigator.pop(ctx);
              addLog('✨ Założono: ${newGear.displayName}!');
            },
            child: const Text('Załóż'),
          ),
        ],
      ),
    );
  }

  void _showItemDetailsDialog(String slotName, NinjaGear gear) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF191716),
        title: Text('$slotName: ${gear.displayName}', style: TextStyle(color: gear.color, fontWeight: FontWeight.bold)),
        content: Text('Rzadkość: ${gear.rarityLabel}\nMoc: +${gear.effectiveStat}', style: const TextStyle(fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zamknij', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  void _openLocationSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161412),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Wybierz lokację eksploracji:', style: TextStyle(color: Color(0xFFFFAB91), fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: shinobiLocations.map((loc) {
                    return Card(
                      color: const Color(0xFF1B1917),
                      child: ListTile(
                        leading: Text(loc.icon, style: const TextStyle(fontSize: 22)),
                        title: Text(loc.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        subtitle: Text('Wymagany poziom: ${loc.minLevel}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            leaveVillage(loc);
                          },
                          child: const Text('Wyrusz', style: TextStyle(fontSize: 10)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFFF8A65))));
    }

    final activeLocation = shinobiLocations.firstWhere((l) => l.id == currentSelectedLocationId);
    final totalItemsInBag = bag.values.fold(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: Text(inVillage ? 'Konohagakure (Baza)' : 'Lokacja: ${activeLocation.name}'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF141211), Color(0xFF0F0E0D)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF191716), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _badge('Ranga', 'Lvl $level', rankColor),
                      _badge('HP', '$hp/$maxHp', const Color(0xFF69F0AE)),
                      _badge('CP', '$chakra/$maxChakra', const Color(0xFF40C4FF)),
                      _badge('Ryo', '$ryo', const Color(0xFFFFD54F)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _itemCard('Broń', currentWeapon, 'Atak: +$totalAttack'),
                      const SizedBox(width: 6),
                      _itemCard('Pancerz', currentArmor, 'Obr: +${currentArmor.effectiveStat}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _itemCard('Głowa', currentHelmet, 'Obr: +${currentHelmet.effectiveStat}'),
                      const SizedBox(width: 6),
                      _itemCard('Buty', currentBoots, 'Obr: +${currentBoots.effectiveStat}'),
                    ],
                  ),
                ],
              ),
            ),

            if (inVillage) ...[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
                        onPressed: _openLocationSelectionModal,
                        icon: const Text('🌲', style: TextStyle(fontSize: 18)),
                        label: const Text('Wyrusz w Las (Wybierz Lokację)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00695C)),
                            onPressed: _openBagDialog,
                            child: Text('🎒 Plecak ($totalItemsInBag)', style: const TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
                            onPressed: _openScrollsDialog,
                            child: Text('📜 Zwoje (${equippedJutsu.length}/3)', style: const TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B1FA2)),
                      onPressed: _openDungeonsDialog,
                      icon: const Text('🏛️'),
                      label: const Text('Legendarne Lochy (Bossowie)'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
                      onPressed: _openBlacksmithDialog,
                      child: const Text('Kowal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                      onPressed: _openMedicDialog,
                      child: const Text('Szpital (Medyk)'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
                        onPressed: proceedExploration,
                        child: const Text('Zbadaj teren / Idź naprzód 🌲', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                      onPressed: returnToVillage,
                      child: const Text('Powrót do Wioski'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _itemCard(String slot, NinjaGear item, String statText) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showItemDetailsDialog(slot, item),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF141211),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: item.color.withAlpha(120)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$slot: ${item.displayName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: item.color)),
                Text(statText, style: const TextStyle(fontSize: 9, color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
