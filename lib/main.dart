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
  BaseGearArchetype(slot: GearSlot.weapon, baseName: 'Standardowy Kunai', baseStat: 4, setGroup: 'none', lore: 'Podstawowe narzędzie każdego ninja.'),
  BaseGearArchetype(slot: GearSlot.weapon, baseName: 'Składany Shuriken Fūma', baseStat: 6, setGroup: 'none', lore: 'Wirujące ostrza.'),
  BaseGearArchetype(slot: GearSlot.weapon, baseName: 'Krótki Miecz Tanto ANBU', baseStat: 8, setGroup: 'anbu', lore: 'Ostrze skrytobójców z Korzenia.'),
  BaseGearArchetype(slot: GearSlot.weapon, baseName: 'Bliźniacze Tasaki Kiri', baseStat: 9, setGroup: 'none', lore: 'Agresywny oręż sieczny z Mgły.'),
  BaseGearArchetype(slot: GearSlot.weapon, baseName: 'Krótki Miecz Chidorigatana', baseStat: 12, setGroup: 'myoboku', lore: 'Ostrze idealnie przewodzące błyskawice.'),
  BaseGearArchetype(slot: GearSlot.armor, baseName: 'Szata Treningowa Genina', baseStat: 3, setGroup: 'none', lore: 'Lekki płócienny strój.'),
  BaseGearArchetype(slot: GearSlot.armor, baseName: 'Kamizelka Jonina Konohy', baseStat: 9, setGroup: 'none', lore: 'Oficjalny pancerz taktyczny.'),
  BaseGearArchetype(slot: GearSlot.armor, baseName: 'Szata Pustelnika Myōboku', baseStat: 13, setGroup: 'myoboku', lore: 'Szata nasycona energią senjutsu.'),
  BaseGearArchetype(slot: GearSlot.helmet, baseName: 'Ochraniacz Czołowy Protektor', baseStat: 2, setGroup: 'none', lore: 'Metalowa płytka z symbolem wioski.'),
  BaseGearArchetype(slot: GearSlot.helmet, baseName: 'Porcelanowa Maska Lisa ANBU', baseStat: 6, setGroup: 'anbu', lore: 'Zaciera tożsamość i aurę czakry.'),
  BaseGearArchetype(slot: GearSlot.boots, baseName: 'Standardowe Sandały Shinobi', baseStat: 2, setGroup: 'none', lore: 'Dobre oparcie stóp na drzewach.'),
  BaseGearArchetype(slot: GearSlot.boots, baseName: 'Drewniane Geta Żabiego Mędrca', baseStat: 9, setGroup: 'myoboku', lore: 'Idealny balans na śliskich skałach.'),
  BaseGearArchetype(slot: GearSlot.trinket, baseName: 'Amulet Ochronny z Liścia', baseStat: 3, setGroup: 'none', lore: 'Błogosławieństwo kaplicy Konohy.'),
  BaseGearArchetype(slot: GearSlot.trinket, baseName: 'Pieczęć Skupienia Czakry', baseStat: 8, setGroup: 'anbu', lore: 'Zmniejsza straty energii przy jutsu.'),
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

  int get effectiveStat => baseStat + (upgradeLevel * (2 + rarity.index)) + bonusValue;
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
  final String id;
  final String name;
  final String title;
  final int baseHp;
  final int baseAtk;
  final String locationId;
  final bool isBoss;

  const EnemyTemplate({
    required this.id,
    required this.name,
    required this.title,
    required this.baseHp,
    required this.baseAtk,
    required this.locationId,
    this.isBoss = false,
  });
}

const List<EnemyTemplate> standardEnemiesPool = [
  EnemyTemplate(id: 'e_dog', name: 'Dziki Ninja-Pies', title: 'Zdziczały Ninken', baseHp: 22, baseAtk: 6, locationId: 'loc_gate'),
  EnemyTemplate(id: 'e_bandit', name: 'Bandyta z Kraju Fal', title: 'Pospolity Rabuś', baseHp: 26, baseAtk: 7, locationId: 'loc_gate'),
  EnemyTemplate(id: 'e_rain', name: 'Zbuntowany Ninja Deszczu', title: 'Nuke-nin z Amegakure', baseHp: 32, baseAtk: 8, locationId: 'loc_forest'),
  EnemyTemplate(id: 'e_rock', name: 'Szpieg z Iwagakure', title: 'Zwiadowca Skały', baseHp: 36, baseAtk: 9, locationId: 'loc_forest'),
  EnemyTemplate(id: 'e_zetsu', name: 'Klon Białego Zetsu', title: 'Infiltrator Mokuton', baseHp: 40, baseAtk: 10, locationId: 'loc_valley'),
  EnemyTemplate(id: 'e_mercenary', name: 'Najemnik z Mgły', title: 'Płatny Zabójca', baseHp: 44, baseAtk: 12, locationId: 'loc_waves'),
  EnemyTemplate(id: 'e_akatsuki_agent', name: 'Agent Cienia Akatsuki', title: 'Posłaniec Zagłady', baseHp: 58, baseAtk: 15, locationId: 'loc_akatsuki'),
];

const List<EnemyTemplate> bossesPool = [
  EnemyTemplate(id: 'b_zabuza', name: 'Zabuza Momochi', title: 'Demon Ukrytej Mgły', baseHp: 95, baseAtk: 16, locationId: 'loc_waves', isBoss: true),
  EnemyTemplate(id: 'b_gaara', name: 'Gaara Pustyni', title: 'Głos Shukaku', baseHp: 120, baseAtk: 19, locationId: 'loc_valley', isBoss: true),
  EnemyTemplate(id: 'b_itachi', name: 'Itachi Uchiha', title: 'Mistrz Mangekyō Sharingana', baseHp: 150, baseAtk: 25, locationId: 'loc_akatsuki', isBoss: true),
];

class ExamStage {
  final int targetRankIndex;
  final String rankTitle;
  final int requiredLevel;
  final String examinerName;
  final String examinerTitle;
  final int hp;
  final int atk;
  final String lore;

  const ExamStage({
    required this.targetRankIndex,
    required this.rankTitle,
    required this.requiredLevel,
    required this.examinerName,
    required this.examinerTitle,
    required this.hp,
    required this.atk,
    required this.lore,
  });
}

const List<ExamStage> shinobiExams = [
  ExamStage(targetRankIndex: 1, rankTitle: 'Genin', requiredLevel: 3, examinerName: 'Iruka Umino', examinerTitle: 'Instruktor Akademii Ninja', hp: 45, atk: 8, lore: '„Pokaż mi, że potrafisz skupić czakrę!”'),
  ExamStage(targetRankIndex: 2, rankTitle: 'Chūnin', requiredLevel: 10, examinerName: 'Ibiki Morino', examinerTitle: 'Dowódca Wydziału Śledczego', hp: 95, atk: 14, lore: '„Sprawdzę Twoją determinację w obliczu bólu!”'),
  ExamStage(targetRankIndex: 3, rankTitle: 'Tokubetsu Jōnin', requiredLevel: 20, examinerName: 'Anko Mitarashi', examinerTitle: 'Egzaminatorka Lasu Śmierci', hp: 145, atk: 19, lore: '„Pora na mordercze tempo!”'),
  ExamStage(targetRankIndex: 4, rankTitle: 'Jōnin Bojowy', requiredLevel: 32, examinerName: 'Kakashi Hatake', examinerTitle: 'Kopiujący Ninja z Konohy', hp: 210, atk: 25, lore: '„Test dwóch dzwonków rozpoczyna się.”'),
  ExamStage(targetRankIndex: 5, rankTitle: 'Legendarny Sannin', requiredLevel: 45, examinerName: 'Jiraiya', examinerTitle: 'Żabi Mędrzec', hp: 285, atk: 31, lore: '„Udowodnij woli ognia!”'),
];

class ShinobiMission {
  final String id;
  final String rank;
  final int minRankIndex;
  final String locationId;
  final String targetEnemyId;
  final String title;
  final String desc;
  final int requiredKills;
  final int rewardRyo;
  final int rewardExp;

  const ShinobiMission({
    required this.id,
    required this.rank,
    required this.minRankIndex,
    required this.locationId,
    required this.targetEnemyId,
    required this.title,
    required this.desc,
    required this.requiredKills,
    required this.rewardRyo,
    required this.rewardExp,
  });
}

const List<ShinobiMission> allMissionsPool = [
  ShinobiMission(id: 'm_d1', rank: 'D', minRankIndex: 0, locationId: 'loc_gate', targetEnemyId: 'e_dog', title: 'Oczyszczenie Bramy z Ninkenów', desc: 'Wyeliminuj 3 Dzikie Ninja-Psy terroryzujące obrzeża.', requiredKills: 3, rewardRyo: 90, rewardExp: 40),
  ShinobiMission(id: 'm_d2', rank: 'D', minRankIndex: 0, locationId: 'loc_gate', targetEnemyId: 'e_bandit', title: 'Ujarzmianie Bandytów', desc: 'Pokonaj 4 Pospolitych Rabusiów przy szlaku.', requiredKills: 4, rewardRyo: 120, rewardExp: 55),
  ShinobiMission(id: 'm_c1', rank: 'C', minRankIndex: 2, locationId: 'loc_forest', targetEnemyId: 'e_rain', title: 'Szpiegostwo w Lesie Śmierci', desc: 'Zneutralizuj 5 Nuke-ninów z Amegakure.', requiredKills: 5, rewardRyo: 250, rewardExp: 110),
  ShinobiMission(id: 'm_c2', rank: 'C', minRankIndex: 2, locationId: 'loc_forest', targetEnemyId: 'e_rock', title: 'Czystka Zwiadowców Skały', desc: 'Eliminacja 5 szpiegów z Iwagakure.', requiredKills: 5, rewardRyo: 280, rewardExp: 125),
  ShinobiMission(id: 'm_b1', rank: 'B', minRankIndex: 3, locationId: 'loc_waves', targetEnemyId: 'e_mercenary', title: 'Zagrożenie z Kraju Fali', desc: 'Pokonaj 6 Płatnych Zabójców.', requiredKills: 6, rewardRyo: 500, rewardExp: 220),
  ShinobiMission(id: 'm_a1', rank: 'A', minRankIndex: 4, locationId: 'loc_akatsuki', targetEnemyId: 'e_akatsuki_agent', title: 'Agentura Cienia', desc: 'Zneutralizuj 6 Posłańców Zagłady w kryjówce.', requiredKills: 6, rewardRyo: 900, rewardExp: 400),
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

  final List<String> log = ['Witaj w Konohagakure! Wybierz lokację w menu, aby rozpocząć rajd.'];

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

  // System Setów Ekwipunku
  Map<String, int> get activeSetCounts {
    Map<String, int> counts = {};
    List<NinjaGear> equipped = [currentWeapon, currentArmor, currentHelmet, currentBoots, currentTrinket];
    for (var gear in equipped) {
      if (gear.setGroup != 'none') {
        counts[gear.setGroup] = (counts[gear.setGroup] ?? 0) + 1;
      }
    }
    return counts;
  }

  int get setBonusAtk {
    int bonus = 0;
    activeSetCounts.forEach((setGroup, count) {
      if (setGroup == 'anbu' && count >= 2) bonus += 5;
      if (setGroup == 'myoboku' && count >= 2) bonus += 8;
      if (count >= 4) bonus += 12;
    });
    return bonus;
  }

  int get setBonusDef {
    int bonus = 0;
    activeSetCounts.forEach((setGroup, count) {
      if (setGroup == 'anbu' && count >= 2) bonus += 4;
      if (setGroup == 'myoboku' && count >= 2) bonus += 6;
      if (count >= 4) bonus += 10;
    });
    return bonus;
  }

  int get totalAttack => currentWeapon.effectiveStat + currentWeapon.bonusValue + currentTrinket.effectiveStat + bonusAtk + setBonusAtk + (level * 2);
  int get totalDefense => currentArmor.effectiveStat + currentArmor.bonusValue + currentHelmet.effectiveStat + currentHelmet.bonusValue + currentBoots.effectiveStat + currentBoots.bonusValue + setBonusDef;

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

      final completedList = prefs.getStringList('completedMissionsHistory');
      if (completedList != null) completedMissionsHistory = completedList.toSet();

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
    await prefs.setStringList('completedMissionsHistory', completedMissionsHistory.toList());

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

      // System utraty niezabezpieczonego ekwipunku w razie porażki w terenie
      if (fallenInBattle) {
        if (!currentWeapon.isSoulbound) currentWeapon = defaultStarterWeapon;
        if (!currentArmor.isSoulbound) currentArmor = defaultStarterArmor;
        if (!currentHelmet.isSoulbound) currentHelmet = defaultStarterHelmet;
        if (!currentBoots.isSoulbound) currentBoots = defaultStarterBoots;
        if (!currentTrinket.isSoulbound) currentTrinket = defaultStarterTrinket;
      }
      bag.clear();
    });

    if (fallenInBattle) {
      addLog('💀 Porażka w terenie! Niezabezpieczony rynsztunek utracono, medyk uratował Ci życie.');
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

  void addCraftingMaterial(String matId, [int count = 1]) {
    craftingBag[matId] = (craftingBag[matId] ?? 0) + count;
    _saveGameData();
  }

  bool useConsumable(Consumable item) {
    bool fromUnsealed = (bag[item.id] ?? 0) > 0;
    bool fromSealed = (sealedBag[item.id] ?? 0) > 0;
    if (!fromUnsealed && !fromSealed) return false;

    setState(() {
      if (fromUnsealed) {
        bag[item.id] = bag[item.id]! - 1;
        if (bag[item.id] == 0) bag.remove(item.id);
      } else {
        sealedBag[item.id] = sealedBag[item.id]! - 1;
        if (sealedBag[item.id] == 0) sealedBag.remove(item.id);
      }

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
          addLog('${item.icon} Pełna regeneracja i limity +${item.value}!');
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

    if (roll < 22) {
      const emptyMessages = [
        '🌿 Spokojna okolica. Nikogo tu nie spotkałeś.',
        '🍃 Wędrówka mija bez echa, las jest niezwykle cichy.',
        '🌳 Cisza i spokój. Wykorzystujesz chwilę na złapanie oddechu.',
        '🌲 Droga jest pusta, słychać jedynie szum wiatru w koronach drzew.'
      ];
      addLog(emptyMessages[_rng.nextInt(emptyMessages.length)]);
    } else if (roll < 60) {
      // Skalowanie spawnrate wrogów według ich mocy (Słabi 55%, Normalni 30%, Silni 15%)
      final locationEnemies = standardEnemiesPool.where((e) => e.locationId == currentSelectedLocationId).toList();
      final enemy = locationEnemies.isNotEmpty ? locationEnemies[_rng.nextInt(locationEnemies.length)] : standardEnemiesPool[0];

      final pRoll = _rng.nextInt(100);
      EnemyPrefix p = pRoll < 55 ? EnemyPrefix.weak : (pRoll < 85 ? EnemyPrefix.normal : EnemyPrefix.strong);
      _startBattleWithEnemy(enemy, forcePrefix: p);
    } else if (roll < 76) {
      final locationBosses = bossesPool.where((b) => b.locationId == currentSelectedLocationId).toList();
      final boss = locationBosses.isNotEmpty ? locationBosses[_rng.nextInt(locationBosses.length)] : bossesPool[0];
      addLog('⚠️ ${loc.name}: Pojawił się potężny boss -> ${boss.name}!');
      _startBattleWithEnemy(boss);
    } else if (roll < 84) {
      _findLoot();
    } else if (roll < 91) {
      _encounterSealMaster();
    } else if (roll < 96) {
      _encounterWanderingSage();
    } else {
      addCraftingMaterial(matDungeonKey, 1);
      addLog('🗝️ Sukces zwiadu! Znaleziono rzadki Klucz do Lochów!');
    }
  }

  void _encounterSealMaster() {
    final unsealedSlots = <GearSlot, NinjaGear>{};
    if (!currentWeapon.isSoulbound) unsealedSlots[GearSlot.weapon] = currentWeapon;
    if (!currentArmor.isSoulbound) unsealedSlots[GearSlot.armor] = currentArmor;
    if (!currentHelmet.isSoulbound) unsealedSlots[GearSlot.helmet] = currentHelmet;
    if (!currentBoots.isSoulbound) unsealedSlots[GearSlot.boots] = currentBoots;
    if (!currentTrinket.isSoulbound) unsealedSlots[GearSlot.trinket] = currentTrinket;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF261214),
        title: const Text('🈴 Wędrowny Mistrz Fūinjutsu', style: TextStyle(color: Color(0xFFFF8A80))),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('„Mogę zapieczętować twój sprzęt przed utratą po powrocie za odpowiednią opłatą w Ryo.”'),
                const SizedBox(height: 10),
                if (unsealedSlots.isEmpty)
                  const Text('Wszystkie założone przedmioty są już zapieczętowane!', style: TextStyle(color: Color(0xFF69F0AE), fontSize: 11))
                else
                  ...unsealedSlots.entries.map((entry) {
                    final slot = entry.key;
                    final gear = entry.value;
                    int cost = gear.rarity.index == 0 ? 150 : 400;
                    String slotName = slot == GearSlot.weapon ? 'Broń' : (slot == GearSlot.armor ? 'Pancerz' : (slot == GearSlot.helmet ? 'Głowa' : (slot == GearSlot.boots ? 'Buty' : 'Talizman')));

                    return ListTile(
                      dense: true,
                      title: Text('$slotName: ${gear.displayName}', style: TextStyle(color: gear.color, fontSize: 11)),
                      subtitle: Text('Koszt: $cost Ryo', style: const TextStyle(fontSize: 9, color: Color(0xFFFFD54F))),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C)),
                        onPressed: ryo >= cost
                            ? () {
                                setState(() {
                                  ryo -= cost;
                                  switch (slot) {
                                    case GearSlot.weapon: currentWeapon = currentWeapon.copyWith(isSoulbound: true); break;
                                    case GearSlot.armor: currentArmor = currentArmor.copyWith(isSoulbound: true); break;
                                    case GearSlot.helmet: currentHelmet = currentHelmet.copyWith(isSoulbound: true); break;
                                    case GearSlot.boots: currentBoots = currentBoots.copyWith(isSoulbound: true); break;
                                    case GearSlot.trinket: currentTrinket = currentTrinket.copyWith(isSoulbound: true); break;
                                  }
                                });
                                _saveGameData();
                                Navigator.pop(ctx);
                                addLog('🈴 Zapieczętowano ${gear.name} (-$cost Ryo)!');
                              }
                            : null,
                        child: const Text('Pieczęć', style: TextStyle(fontSize: 9)),
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
      ),
    );
  }

  void _encounterWanderingSage() {
    final unlearnedJutsu = allJutsuPool.where((j) => !knownJutsu.any((k) => k.id == j.id)).toList();
    if (unlearnedJutsu.isEmpty) {
      addLog('👴🏻 Spotkano Wędrownego Mędrca, ale znasz już jego techniki.');
      return;
    }
    final offered = unlearnedJutsu[_rng.nextInt(unlearnedJutsu.length)];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1814),
        title: const Text('👴🏻 Wędrowny Mędrzec', style: TextStyle(color: Color(0xFFFFD54F))),
        content: Text('„Chcesz posiąść zwój techniki [${offered.name}] za ${offered.costRyo} Ryo?”'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Odejdź', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
            onPressed: ryo >= offered.costRyo
                ? () {
                    setState(() {
                      ryo -= offered.costRyo;
                      knownJutsu.add(offered);
                    });
                    _saveGameData();
                    Navigator.pop(ctx);
                    addLog('📜 Poznano nowe Jutsu: [${offered.name}]!');
                  }
                : null,
            child: const Text('Kup'),
          ),
        ],
      ),
    );
  }

  void _openMedicDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setMedicState) {
          // Skalowana cena treningu witalności
          final int vitalCost = 180 + (vitalTrainingCount * 65) + (vitalTrainingCount * vitalTrainingCount * 15);

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
                      subtitle: const Text('+10 Max HP i +10 Max CP (rosnący koszt)', style: TextStyle(fontSize: 10, color: Colors.white60)),
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
                                addLog('✨ Rozwinięto witalność za $vitalCost Ryo.');
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
                                              addLog('⚠️ Kucie nie powiodło się, materiały przepadły.');
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

  void _openVillageMissionsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setMissionState) {
          final nextExam = shinobiExams.firstWhere(
            (e) => e.targetRankIndex == passedRankIndex + 1,
            orElse: () => shinobiExams.last,
          );
          final bool hasPendingExam = passedRankIndex < 5 && level >= nextExam.requiredLevel;

          return AlertDialog(
            backgroundColor: const Color(0xFF1A1816),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFFFB74D), width: 1.2)),
            title: const Text('📜 Biuro Misji i Egzaminów', style: TextStyle(color: Color(0xFFFFB74D), fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (passedRankIndex < 5) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: hasPendingExam ? const Color(0xFF2E1C0A) : const Color(0xFF141211),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: hasPendingExam ? const Color(0xFFFFD54F) : Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('🥋 Egzamin na ${nextExam.rankTitle}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: hasPendingExam ? const Color(0xFFFFD54F) : Colors.white70)),
                                Text('Wymaga: Lvl ${nextExam.requiredLevel}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('Egzaminator: ${nextExam.examinerName} (${nextExam.examinerTitle})', style: const TextStyle(fontSize: 10, color: Colors.white70)),
                            const SizedBox(height: 6),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasPendingExam ? const Color(0xFFE65100) : const Color(0xFF37474F),
                                minimumSize: const Size(double.infinity, 30),
                              ),
                              onPressed: hasPendingExam
                                  ? () {
                                      Navigator.pop(ctx);
                                      _startBattleWithEnemy(
                                        EnemyTemplate(id: 'exam', name: nextExam.examinerName, title: nextExam.examinerTitle, baseHp: nextExam.hp, baseAtk: nextExam.atk, locationId: '', isBoss: true),
                                        isExamFight: true,
                                        examTargetRank: nextExam.targetRankIndex,
                                      );
                                    }
                                  : null,
                              child: Text(hasPendingExam ? 'Rozpocznij Egzamin!' : 'Osiągnij Lvl ${nextExam.requiredLevel}', style: const TextStyle(fontSize: 10)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    const Text('Zlecenia Hokage (z podziałem na lokacje):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFFFAB91))),
                    const SizedBox(height: 6),

                    if (activeMissionIndex != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF141211), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF69F0AE).withAlpha(140))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Aktywna Misja: Ranga ${allMissionsPool[activeMissionIndex!].rank}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFFFD54F))),
                            Text(allMissionsPool[activeMissionIndex!].title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: currentMissionKills / allMissionsPool[activeMissionIndex!].requiredKills,
                                color: const Color(0xFF69F0AE),
                                backgroundColor: Colors.white12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text('Postęp: $currentMissionKills / ${allMissionsPool[activeMissionIndex!].requiredKills}', style: const TextStyle(fontSize: 10)),
                            const SizedBox(height: 6),
                            if (currentMissionKills >= allMissionsPool[activeMissionIndex!].requiredKills)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), minimumSize: const Size(double.infinity, 28)),
                                onPressed: () {
                                  final m = allMissionsPool[activeMissionIndex!];
                                  setState(() {
                                    ryo += m.rewardRyo;
                                    completedMissionsHistory.add(m.id);
                                    activeMissionIndex = null;
                                    currentMissionKills = 0;
                                  });
                                  addExperience(m.rewardExp);
                                  _saveGameData();
                                  Navigator.pop(ctx);
                                  addLog('🎖️ Sukces misji: ${m.title}! +${m.rewardRyo} Ryo, +${m.rewardExp} EXP');
                                },
                                child: const Text('Odbierz Nagrodę! 🎁', style: TextStyle(fontSize: 10)),
                              )
                            else
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    activeMissionIndex = null;
                                    currentMissionKills = 0;
                                  });
                                  _saveGameData();
                                  Navigator.pop(ctx);
                                  addLog('❌ Porzucono zlecenie.');
                                },
                                child: const Text('Porzuć misję', style: TextStyle(color: Color(0xFFFF5252), fontSize: 10)),
                              ),
                          ],
                        ),
                      )
                    else
                      ...shinobiLocations.map((loc) {
                        final locMissions = allMissionsPool.where((m) => m.locationId == loc.id).toList();
                        if (locMissions.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text('${loc.icon} ${loc.name}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF80D8FF))),
                            ),
                            ...locMissions.map((m) {
                              final bool isUnlocked = passedRankIndex >= m.minRankIndex;
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    radius: 13,
                                    backgroundColor: isUnlocked ? const Color(0xFFE65100) : const Color(0xFF263238),
                                    child: Text(m.rank, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: isUnlocked ? Colors.white : Colors.white38)),
                                  ),
                                  title: Text(m.title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isUnlocked ? Colors.white : Colors.white38)),
                                  subtitle: Text('Nagroda: ${m.rewardRyo} Ryo | +${m.rewardExp} EXP', style: const TextStyle(fontSize: 9, color: Colors.white60)),
                                  trailing: isUnlocked
                                      ? ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100), padding: const EdgeInsets.symmetric(horizontal: 8)),
                                          onPressed: () {
                                            setState(() {
                                              activeMissionIndex = allMissionsPool.indexOf(m);
                                              currentMissionKills = 0;
                                            });
                                            _saveGameData();
                                            Navigator.pop(ctx);
                                            addLog('📜 Przyjęto zlecenie: ${m.title}!');
                                          },
                                          child: const Text('Przyjmij', style: TextStyle(fontSize: 9)),
                                        )
                                      : const Icon(Icons.lock, size: 16, color: Colors.grey),
                                ),
                              );
                            }),
                            const Divider(color: Colors.white12),
                          ],
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
                                          EnemyTemplate(id: boss.id, name: boss.name, title: boss.title, baseHp: boss.baseHp, baseAtk: boss.baseAtk, locationId: '', isBoss: true),
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

  void _startBattleWithEnemy(EnemyTemplate template, {EnemyPrefix forcePrefix = EnemyPrefix.normal, bool isExamFight = false, int? examTargetRank}) {
    double hpMult = 1.0;
    double atkMult = 1.0;
    String prefixTitle = '';
    Color prefixColor = const Color(0xFFFFA726);

    if (!template.isBoss && !isExamFight) {
      switch (forcePrefix) {
        case EnemyPrefix.weak:
          hpMult = 0.75;
          atkMult = 0.8;
          prefixTitle = 'Słaby ';
          prefixColor = const Color(0xFFCFD8DC);
          break;
        case EnemyPrefix.normal:
          hpMult = 1.0;
          atkMult = 1.0;
          prefixTitle = '';
          prefixColor = const Color(0xFFFFA726);
          break;
        case EnemyPrefix.strong:
          hpMult = 1.35;
          atkMult = 1.25;
          prefixTitle = 'Silny ⚠️ ';
          prefixColor = const Color(0xFFFF5252);
          break;
      }
    }

    final int enemyMaxHp = (template.baseHp * hpMult).round();
    final int enemyBaseAtk = (template.baseAtk * atkMult).round();
    int enemyHp = enemyMaxHp;

    String initialMsg = isExamFight ? '🥋 EGZAMIN: Egzaminator ${template.name} atakuje!' : (template.isBoss ? '⚠️ BOSS: Pojawia się ${template.name}!' : 'Z cienia atakuje $prefixTitle${template.name}!');
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

              final rawDmg = enemyBaseAtk + _rng.nextInt(4);
              final dmg = max(2, rawDmg - (totalDefense ~/ 2));

              setState(() {
                hp = max(0, hp - dmg);
              });
              appendBattleLog('${template.name} zadaje Ci $dmg obrażeń.');
              _saveGameData();

              if (hp <= 0) {
                Navigator.pop(ctx);
                if (isExamFight) {
                  setState(() => hp = 1);
                  addLog('❌ Egzamin oblany!');
                } else {
                  returnToVillage(fallenInBattle: true);
                }
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

                if (isExamFight) {
                  setState(() => passedRankIndex = examTargetRank!);
                  addExperience(250);
                  addLog('🏆 ZDANO EGZAMIN na rangę: $ninjaRank!');
                  return;
                }

                final rewardRyo = template.isBoss ? 80 : 15;
                final expGained = template.isBoss ? 35 : 10;

                setState(() {
                  ryo += rewardRyo;
                  if (activeMissionIndex != null) {
                    final activeMission = allMissionsPool[activeMissionIndex!];
                    if (activeMission.targetEnemyId == template.id) {
                      currentMissionKills++;
                    }
                  }
                });
                addExperience(expGained);
                addLog('🏆 Zwycięstwo nad $prefixTitle${template.name}! +$rewardRyo Ryo, +$expGained EXP.');
                _findLoot(guaranteedBossDrop: template.isBoss);
              } else {
                enemyTurn();
                setBattleState(() {});
              }
            }

            void useBattleItem(Consumable item) {
              if (useConsumable(item)) {
                appendBattleLog('Użyto ${item.name}!');
                enemyTurn();
                setBattleState(() {});
              } else {
                appendBattleLog('Brak przedmiotów ${item.name}!');
                setBattleState(() {});
              }
            }

            void openCombatBagDialog() {
              showDialog(
                context: context,
                builder: (bagCtx) => AlertDialog(
                  backgroundColor: const Color(0xFF191716),
                  title: const Text('🎒 Użyj zapasu w walce', style: TextStyle(color: Color(0xFFFFB74D), fontSize: 14)),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: bag.isEmpty
                        ? const Text('Brak przedmiotów w plecaku!', style: TextStyle(fontSize: 11, color: Colors.white54))
                        : ListView(
                            shrinkWrap: true,
                            children: bag.entries.map((entry) {
                              final item = allConsumables.firstWhere((c) => c.id == entry.key);
                              return ListTile(
                                dense: true,
                                leading: Text(item.icon),
                                title: Text('${item.name} (x${entry.value})', style: const TextStyle(fontSize: 11)),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00695C), padding: const EdgeInsets.symmetric(horizontal: 8)),
                                  onPressed: () {
                                    Navigator.pop(bagCtx);
                                    useBattleItem(item);
                                    setBattleState(() {});
                                  },
                                  child: const Text('Użyj', style: TextStyle(fontSize: 9)),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.all(16),
              height: 520,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$prefixTitle${template.name}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: prefixColor)),
                      Text('$enemyHp / $enemyMaxHp HP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: enemyHp / enemyMaxHp, color: const Color(0xFFEF5350), backgroundColor: Colors.white12, minHeight: 6),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('Twoje HP: $hp / $maxHp', style: const TextStyle(fontSize: 11, color: Color(0xFF69F0AE), fontWeight: FontWeight.bold)),
                      Text('Twoje CP: $chakra / $maxChakra', style: const TextStyle(fontSize: 11, color: Color(0xFF40C4FF), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 90,
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00695C), padding: const EdgeInsets.symmetric(vertical: 10)),
                          onPressed: openCombatBagDialog,
                          child: const Text('🎒 Plecak w walce', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF37474F), padding: const EdgeInsets.symmetric(vertical: 10)),
                          onPressed: () {
                            if (template.isBoss || isExamFight) {
                              appendBattleLog('Nie można uciec z tej walki!');
                              setBattleState(() {});
                              return;
                            }
                            Navigator.pop(ctx);
                            addLog('💨 Ucieczka z pola walki!');
                          },
                          child: const Text('💨 Ucieczka', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
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
      if (roll > 95) {
        rarity = ItemRarity.legendary;
      } else if (roll > 82) {
        rarity = ItemRarity.epic;
      } else if (roll > 60) {
        rarity = ItemRarity.rare;
      }
    }

    final arch = standardArchetypesPool.where((a) => a.slot == slot).toList();
    final chosen = arch[_rng.nextInt(arch.length)];
    
    String prefix = '';
    if (rarity == ItemRarity.rare) prefix = 'Mistrzowski ';
    if (rarity == ItemRarity.epic) prefix = 'Pradawny ';
    if (rarity == ItemRarity.legendary) prefix = 'Legendarny ';

    int bonusAttr = rarity.index;

    return NinjaGear(
      name: '$prefix${chosen.baseName}',
      rarity: rarity,
      baseStat: chosen.baseStat + (rarity.index * 3) + _rng.nextInt(2),
      bonusEffect: bonusAttr > 0 ? 'MocŻywiołu' : 'Brak',
      bonusValue: bonusAttr,
      setGroup: chosen.setGroup,
      isSoulbound: false,
    );
  }

  void _showEquipDialog({required NinjaGear newGear, required NinjaGear currentGear, required GearSlot slot}) {
    String slotName = slot == GearSlot.weapon ? 'Broń' : (slot == GearSlot.armor ? 'Pancerz' : (slot == GearSlot.helmet ? 'Głowa' : (slot == GearSlot.boots ? 'Buty' : 'Talizman')));
    int diff = newGear.effectiveStat - currentGear.effectiveStat;
    String diffText = diff > 0 ? '+$diff' : '$diff';
    Color diffColor = diff > 0 ? const Color(0xFF69F0AE) : (diff < 0 ? const Color(0xFFFF5252) : Colors.grey);

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
                  Row(
                    children: [
                      Text('Moc: +${newGear.effectiveStat} ', style: const TextStyle(fontSize: 11)),
                      Text('($diffText)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: diffColor)),
                    ],
                  ),
                  if (newGear.setGroup != 'none')
                    Text('Set: ${newGear.setGroup.toUpperCase()}', style: const TextStyle(fontSize: 10, color: Color(0xFF80D8FF))),
                  if (newGear.bonusValue > 0)
                    Text('Atuty: +${newGear.bonusValue} dodatkowych statystyk', style: const TextStyle(fontSize: 10, color: Color(0xFFFFD54F))),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rzadkość: ${gear.rarityLabel}', style: TextStyle(color: gear.color, fontSize: 12)),
            const SizedBox(height: 4),
            Text('Moc: +${gear.effectiveStat}', style: const TextStyle(fontSize: 12)),
            if (gear.setGroup != 'none')
              Text('Zestaw (Set): ${gear.setGroup.toUpperCase()}', style: const TextStyle(fontSize: 11, color: Color(0xFF80D8FF))),
            if (gear.bonusValue > 0)
              Text('Dodatkowe atuty: +${gear.bonusValue}', style: const TextStyle(fontSize: 11, color: Color(0xFFFFD54F))),
            const SizedBox(height: 6),
            Text(gear.isSoulbound ? '📜 Przedmiot zapieczętowany (bezpieczny)' : '⚠️ Przedmiot niezabezpieczony', style: TextStyle(fontSize: 10, color: gear.isSoulbound ? const Color(0xFF69F0AE) : const Color(0xFFFF5252))),
          ],
        ),
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
                      _badge('Ranga', 'Lvl $level ($ninjaRank)', rankColor),
                      _badge('EXP', '$ninjaExp / $expForNextLevel', const Color(0xFF80D8FF)),
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _itemCard('Talizman', currentTrinket, 'Moc: +${currentTrinket.effectiveStat}'),
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
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037), padding: const EdgeInsets.symmetric(vertical: 10)),
                            onPressed: _openVillageMissionsDialog,
                            child: const Text('📜 Biuro Misji', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00695C), padding: const EdgeInsets.symmetric(vertical: 10)),
                            onPressed: _openBagDialog,
                            child: Text('🎒 Plecak ($totalItemsInBag)', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), padding: const EdgeInsets.symmetric(vertical: 10)),
                            onPressed: _openScrollsDialog,
                            child: Text('📜 Zwoje (${equippedJutsu.length}/3)', style: TextStyle(fontSize: 11)),
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Align(alignment: Alignment.centerLeft, child: Text('Dziennik (Ostatnie zdarzenie):', style: TextStyle(color: Colors.grey, fontSize: 10))),
              ),
              Container(
                height: 48,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF121110),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    child: Text(
                      log.isNotEmpty ? log.first : 'Wyprawa trwa...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'monospace', color: Color(0xFFFFCC80), fontSize: 11),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00695C), padding: const EdgeInsets.symmetric(vertical: 12)),
                        onPressed: _openBagDialog,
                        child: const Text('🎒 Plecak', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100), padding: const EdgeInsets.symmetric(vertical: 12)),
                        onPressed: proceedExploration,
                        child: const Text('Idź naprzód 🌲', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 12)),
                        onPressed: returnToVillage,
                        child: const Text('Powrót', style: TextStyle(fontSize: 11)),
                      ),
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
              border: Border.all(color: item.isSoulbound ? const Color(0xFFFFD54F) : item.color.withAlpha(120)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('$slot: ${item.displayName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: item.color)),
                    ),
                    if (item.isSoulbound) const Text(' 📜', style: TextStyle(fontSize: 9)),
                  ],
                ),
                Text(statText, style: const TextStyle(fontSize: 9, color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
