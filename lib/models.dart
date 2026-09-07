import 'package:flutter/material.dart';

enum ItemRarity { common, rare, epic, legendary }

enum GearSlot { weapon, armor, helmet, boots, trinket }

enum AffixType {
  critRate,
  dodgeRate,
  armorPierce,
  lifeSteal,
  hpRegen,
  chakraRegen,
  bonusHp,
  bonusChakra,
}

enum BossTrait {
  ironSkin,
  bloodEnrage,
  chakraLeech,
  chakraThorns,
  dodgeManiac,
  poisonMaster,
}

enum EnemyPrefix { weak, normal, strong }

enum JutsuType { damage, healing, shield, stun }

enum ConsumableType { healHpPercent, healCpPercent, ramenRestore, buffAtk, smokeEscape, directDmg }

enum MissionType { killCount, bossHunt, itemSupply }

const String matIronOre = 'mat_iron_ore';
const String matSteel = 'mat_steel';
const String matCrystal = 'mat_crystal';
const String matDungeonKey = 'mat_dungeon_key';

class CraftingMaterialInfo {
  final String id;
  final String name;
  final String icon;
  final String description;

  const CraftingMaterialInfo({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });
}

const Map<String, CraftingMaterialInfo> craftingMaterials = {
  matIronOre: CraftingMaterialInfo(
    id: matIronOre,
    name: 'Ruda Żelaza',
    icon: '🪨',
    description: 'Pospolity surowiec kowalski do ulepszania rynsztunku na poziomy +1 do +3.',
  ),
  matSteel: CraftingMaterialInfo(
    id: matSteel,
    name: 'Hartowana Stal',
    icon: '🧱',
    description: 'Rzadki metal shinobi potrzebny do ulepszeń rynsztunku na poziomy +4 do +6.',
  ),
  matCrystal: CraftingMaterialInfo(
    id: matCrystal,
    name: 'Kryształ Czakry',
    icon: '💎',
    description: 'Skrystalizowana energia używana do mistrzowskich ulepszeń rynsztunku na +7 do +9.',
  ),
  matDungeonKey: CraftingMaterialInfo(
    id: matDungeonKey,
    name: 'Klucz do Lochu',
    icon: '🗝️',
    description: 'Starożytny klucz otwierający wrota do legendarnego lochu w Wiosce.',
  ),
};

class GearAffix {
  final AffixType type;
  final int value;

  const GearAffix({required this.type, required this.value});

  String get label {
    switch (type) {
      case AffixType.critRate: return '+$value% Szansa na Krytyk';
      case AffixType.dodgeRate: return '+$value% Unik (Kawarimi)';
      case AffixType.armorPierce: return '+$value% Przebicie Pancerza';
      case AffixType.lifeSteal: return '+$value% Kradzież Życia (Lifesteal)';
      case AffixType.hpRegen: return '+$value HP/turę (Regeneracja)';
      case AffixType.chakraRegen: return '+$value CP/turę (Medytacja)';
      case AffixType.bonusHp: return '+$value Max HP';
      case AffixType.bonusChakra: return '+$value Max CP';
    }
  }

  Map<String, dynamic> toJson() => {'type': type.index, 'value': value};

  factory GearAffix.fromJson(Map<String, dynamic> json) {
    return GearAffix(
      type: AffixType.values[json['type'] as int],
      value: json['value'] as int,
    );
  }
}

class NinjaGear {
  final String name;
  final ItemRarity rarity;
  final GearSlot slot;
  final int baseStat;
  final int upgradeLevel;
  final List<GearAffix> affixes;
  final String setGroup;
  final bool isSoulbound;
  final bool isFavorite;
  final String icon;

  const NinjaGear({
    required this.name,
    required this.rarity,
    required this.slot,
    required this.baseStat,
    this.upgradeLevel = 0,
    this.affixes = const [],
    this.setGroup = 'none',
    this.isSoulbound = false,
    this.isFavorite = false,
    this.icon = '🗡️',
  });

  bool get isBossSet => setGroup.startsWith('boss_');
  bool get isFactionSet => setGroup != 'none' && !isBossSet;

  int get effectiveStat => baseStat + (upgradeLevel * 4);

  int getAffixValue(AffixType type) {
    int total = 0;
    for (var a in affixes) {
      if (a.type == type) total += a.value;
    }
    return total;
  }

  String get displayName {
    final upText = upgradeLevel > 0 ? ' +$upgradeLevel' : '';
    return '$name$upText';
  }

  String get rarityLabel {
    switch (rarity) {
      case ItemRarity.common: return 'Zwykły';
      case ItemRarity.rare: return 'Rzadki';
      case ItemRarity.epic: return 'Epicki';
      case ItemRarity.legendary: return 'Legendarny';
    }
  }

  Color get color {
    switch (rarity) {
      case ItemRarity.common: return const Color(0xFFB0BEC5);
      case ItemRarity.rare: return const Color(0xFF42A5F5);
      case ItemRarity.epic: return const Color(0xFFAB47BC);
      case ItemRarity.legendary: return const Color(0xFFFFB300);
    }
  }

  Color get borderColor {
    if (isBossSet) return const Color(0xFFFF1744);
    return color;
  }

  double get borderWidth => isBossSet ? 2.2 : (rarity.index >= 2 ? 1.8 : 1.2);

  int get marketValue {
    int base = (baseStat * 7) + (upgradeLevel * 25);
    int rarityMult = (rarity.index + 1) * 12;
    int affixBonus = affixes.length * 15;
    return base + rarityMult + affixBonus;
  }

  int get sellPrice => (marketValue * 0.22).round();
  int get merchantSellPrice => (marketValue * 0.45).round();
  int get sealingCost => (marketValue * 0.55).round();

  NinjaGear copyWith({
    String? name,
    ItemRarity? rarity,
    GearSlot? slot,
    int? baseStat,
    int? upgradeLevel,
    List<GearAffix>? affixes,
    String? setGroup,
    bool? isSoulbound,
    bool? isFavorite,
    String? icon,
  }) {
    return NinjaGear(
      name: name ?? this.name,
      rarity: rarity ?? this.rarity,
      slot: slot ?? this.slot,
      baseStat: baseStat ?? this.baseStat,
      upgradeLevel: upgradeLevel ?? this.upgradeLevel,
      affixes: affixes ?? this.affixes,
      setGroup: setGroup ?? this.setGroup,
      isSoulbound: isSoulbound ?? this.isSoulbound,
      isFavorite: isFavorite ?? this.isFavorite,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'rarity': rarity.index,
    'slot': slot.index,
    'baseStat': baseStat,
    'upgradeLevel': upgradeLevel,
    'affixes': affixes.map((a) => a.toJson()).toList(),
    'setGroup': setGroup,
    'isSoulbound': isSoulbound,
    'isFavorite': isFavorite,
    'icon': icon,
  };

  factory NinjaGear.fromJson(Map<String, dynamic> json) {
    return NinjaGear(
      name: json['name'] as String,
      rarity: ItemRarity.values[json['rarity'] as int],
      slot: GearSlot.values[json['slot'] as int],
      baseStat: json['baseStat'] as int,
      upgradeLevel: json['upgradeLevel'] as int? ?? 0,
      affixes: (json['affixes'] as List? ?? [])
          .map((a) => GearAffix.fromJson(a as Map<String, dynamic>))
          .toList(),
      setGroup: json['setGroup'] as String? ?? 'none',
      isSoulbound: json['isSoulbound'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      icon: json['icon'] as String? ?? '🗡️',
    );
  }
}

class EnemyTemplate {
  final String id;
  final String name;
  final String title;
  final int baseHp;
  final int baseAtk;
  final String locationId;
  final bool isBoss;
  final String icon;
  final int critRate;
  final int dodgeRate;
  final int armorPierce;
  final int flatBlock;
  final List<BossTrait> traits;

  const EnemyTemplate({
    required this.id,
    required this.name,
    this.title = '',
    required this.baseHp,
    required this.baseAtk,
    required this.locationId,
    this.isBoss = false,
    this.icon = '🥷',
    this.critRate = 5,
    this.dodgeRate = 5,
    this.armorPierce = 0,
    this.flatBlock = 0,
    this.traits = const [],
  });

  double get powerRating => (baseHp * 0.45) + (baseAtk * 2.2);
}

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

class Jutsu {
  final String id;
  final String name;
  final int chakraCost;
  final double powerMultiplier;
  final JutsuType type;
  final int effectValue;
  final String effectDescription;
  final int costRyo;
  final int minRankIndex;
  final bool availableInVillage;
  final Color color;

  const Jutsu({
    required this.id,
    required this.name,
    required this.chakraCost,
    required this.powerMultiplier,
    required this.type,
    required this.effectValue,
    required this.effectDescription,
    required this.costRyo,
    this.minRankIndex = 0,
    this.availableInVillage = true,
    required this.color,
  });
}

class Consumable {
  final String id;
  final String name;
  final ConsumableType type;
  final int value;
  final int price;
  final String description;
  final String statBonusText;
  final String icon;

  const Consumable({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.price,
    required this.description,
    required this.statBonusText,
    required this.icon,
  });
}

class ShinobiExam {
  final int targetRankIndex;
  final String rankTitle;
  final int requiredLevel;
  final String examinerName;
  final String examinerTitle;
  final int hp;
  final int atk;
  final int critRate;
  final int dodgeRate;
  final String icon;

  const ShinobiExam({
    required this.targetRankIndex,
    required this.rankTitle,
    required this.requiredLevel,
    required this.examinerName,
    required this.examinerTitle,
    required this.hp,
    required this.atk,
    required this.critRate,
    required this.dodgeRate,
    required this.icon,
  });
}

class Mission {
  final String id;
  final String title;
  final String desc;
  final String rank;
  final int minRankIndex;
  final String locationId;
  final MissionType type;
  final String? targetEnemyId;
  final String? supplyItemId;
  final int requiredCount;
  final int rewardRyo;
  final int rewardExp;

  const Mission({
    required this.id,
    required this.title,
    required this.desc,
    required this.rank,
    required this.minRankIndex,
    required this.locationId,
    required this.type,
    this.targetEnemyId,
    this.supplyItemId,
    required this.requiredCount,
    required this.rewardRyo,
    required this.rewardExp,
  });
}

class MilestoneTracker {
  int physicalHitsDealt;
  int jutsuCasts;
  int damageTaken;
  int enemiesSlain;
  int bountiesClaimed;

  MilestoneTracker({
    this.physicalHitsDealt = 0,
    this.jutsuCasts = 0,
    this.damageTaken = 0,
    this.enemiesSlain = 0,
    this.bountiesClaimed = 0,
  });

  Map<String, dynamic> toJson() => {
    'physicalHitsDealt': physicalHitsDealt,
    'jutsuCasts': jutsuCasts,
    'damageTaken': damageTaken,
    'enemiesSlain': enemiesSlain,
    'bountiesClaimed': bountiesClaimed,
  };

  factory MilestoneTracker.fromJson(Map<String, dynamic> json) {
    return MilestoneTracker(
      physicalHitsDealt: json['physicalHitsDealt'] as int? ?? 0,
      jutsuCasts: json['jutsuCasts'] as int? ?? 0,
      damageTaken: json['damageTaken'] as int? ?? 0,
      enemiesSlain: json['enemiesSlain'] as int? ?? 0,
      bountiesClaimed: json['bountiesClaimed'] as int? ?? 0,
    );
  }
}

class BingoTarget {
  final String id;
  final String name;
  final String title;
  final String zoneId;
  final int minDepth;
  final EnemyTemplate enemy;
  final NinjaGear exclusiveReward;
  final int bountyRyo;
  final int bountyExp;
  bool isDefeated;

  BingoTarget({
    required this.id,
    required this.name,
    required this.title,
    required this.zoneId,
    required this.minDepth,
    required this.enemy,
    required this.exclusiveReward,
    required this.bountyRyo,
    required this.bountyExp,
    this.isDefeated = false,
  });
}

class DungeonBoss {
  final String id;
  final String name;
  final String title;
  final int minLevel;
  final int baseHp;
  final int baseAtk;
  final String setGroup;
  final String icon;

  const DungeonBoss({
    required this.id,
    required this.name,
    required this.title,
    required this.minLevel,
    required this.baseHp,
    required this.baseAtk,
    required this.setGroup,
    required this.icon,
  });
}

class GearArchetype {
  final String baseName;
  final GearSlot slot;
  final int baseStat;
  final String setGroup;
  final String icon;

  const GearArchetype({
    required this.baseName,
    required this.slot,
    required this.baseStat,
    this.setGroup = 'none',
    required this.icon,
  });
}

// ==========================================
// PULE DANYCH (DATA POOLS)
// ==========================================

const List<ShinobiLocation> shinobiLocations = [
  ShinobiLocation(
    id: 'loc_gate',
    name: 'Brama Główna i Obrzeża',
    minLevel: 1,
    description: 'Teren wokół murów Konohy. Grasują tu drobni bandyci, wrogi zwiad oraz dzikie psy.',
    icon: '⛩️',
  ),
  ShinobiLocation(
    id: 'loc_forest',
    name: 'Las Śmierci (Egzamin)',
    minLevel: 8,
    description: 'Mroczny poligon pełen trujących stworzeń, zdziczałych bestii i wrogich geninów.',
    icon: '🌲',
  ),
  ShinobiLocation(
    id: 'loc_waves',
    name: 'Kraj Fali i Most Naruto',
    minLevel: 18,
    description: 'Wilgotne pomosty i zamglone wybrzeża opanowane przez najemników Gatō i zbuntowanych shinobi.',
    icon: '🌊',
  ),
  ShinobiLocation(
    id: 'loc_valley',
    name: 'Dolina Końca',
    minLevel: 30,
    description: 'Kanion z posągami założycieli, nasycony pradawną rywalizacją, czakrą klonów i kultystami pieczęci.',
    icon: '⚡',
  ),
  ShinobiLocation(
    id: 'loc_akatsuki',
    name: 'Kryjówka Akatsuki',
    minLevel: 45,
    description: 'Podziemna grota zabezpieczona pieczęciami, strzeżona przez elitarne marionetki i zmutowane bestie.',
    icon: '☁️',
  ),
];

const List<EnemyTemplate> standardEnemiesPool = [
  // --- LOKACJA 1: BRAMA GŁÓWNA I OBRZEŻA (loc_gate) ---
  EnemyTemplate(id: 'e_gate_1', name: 'Bandzior z Gościńca', baseHp: 65, baseAtk: 9, locationId: 'loc_gate', icon: '🥷'),
  EnemyTemplate(id: 'e_gate_2', name: 'Zwiadowca Mgły', baseHp: 75, baseAtk: 11, locationId: 'loc_gate', icon: '👤', dodgeRate: 8),
  EnemyTemplate(id: 'e_gate_3', name: 'Młody Genin Dźwięku', baseHp: 85, baseAtk: 13, locationId: 'loc_gate', icon: '🎶'),
  EnemyTemplate(id: 'e_gate_4', name: 'Dezerter Piasku', baseHp: 95, baseAtk: 14, locationId: 'loc_gate', icon: '🏜️', flatBlock: 2),
  EnemyTemplate(id: 'e_gate_5', name: 'Szpieg Trawy', baseHp: 80, baseAtk: 15, locationId: 'loc_gate', icon: '🍃', critRate: 8),
  EnemyTemplate(id: 'e_gate_ninken', name: 'Dziki Ninken z Obrzeży', baseHp: 70, baseAtk: 12, locationId: 'loc_gate', icon: '🐕', critRate: 10),

  // --- LOKACJA 2: LAS ŚMIERCI (loc_forest) ---
  EnemyTemplate(id: 'e_forest_1', name: 'Wielka Pijawka Bagienna', baseHp: 140, baseAtk: 19, locationId: 'loc_forest', icon: '🪱'),
  EnemyTemplate(id: 'e_forest_2', name: 'Kroczący Olbrzymi Wij', baseHp: 165, baseAtk: 21, locationId: 'loc_forest', icon: '🐛', flatBlock: 4),
  EnemyTemplate(id: 'e_forest_3', name: 'Genin Deszczu (Truciciel)', baseHp: 150, baseAtk: 23, locationId: 'loc_forest', icon: '🌧️', traits: [BossTrait.poisonMaster]),
  EnemyTemplate(id: 'e_forest_4', name: 'Skrytobójca z Lasu Śmierci', baseHp: 135, baseAtk: 26, locationId: 'loc_forest', icon: '🗡️', critRate: 12),
  EnemyTemplate(id: 'e_forest_5', name: 'Zmutowany Klon Drzewny', baseHp: 190, baseAtk: 18, locationId: 'loc_forest', icon: '🪵'),
  EnemyTemplate(id: 'e_forest_ninken', name: 'Mroczny Ogar Tropiący Lasu', baseHp: 145, baseAtk: 24, locationId: 'loc_forest', icon: '🐺', dodgeRate: 15),

  // --- LOKACJA 3: KRAJ FALI (loc_waves) ---
  EnemyTemplate(id: 'e_waves_1', name: 'Najemnik Kartelu Gatō', baseHp: 230, baseAtk: 31, locationId: 'loc_waves', icon: '💰'),
  EnemyTemplate(id: 'e_waves_2', name: 'Bandyta Krwawego Miecza', baseHp: 250, baseAtk: 34, locationId: 'loc_waves', icon: '⚔️', critRate: 12),
  EnemyTemplate(id: 'e_waves_3', name: 'Ronin Ukrytej Mgły', baseHp: 220, baseAtk: 38, locationId: 'loc_waves', icon: '🌫️', dodgeRate: 12),
  EnemyTemplate(id: 'e_waves_4', name: 'Skrytobójca z Kusari-gama', baseHp: 240, baseAtk: 36, locationId: 'loc_waves', icon: '⛓️', armorPierce: 12),
  EnemyTemplate(id: 'e_waves_5', name: 'Zbuntowany Suitonowiec', baseHp: 270, baseAtk: 32, locationId: 'loc_waves', icon: '💧'),
  EnemyTemplate(id: 'e_waves_ninken', name: 'Mglisty Ogar Bojowy Zabuzy', baseHp: 225, baseAtk: 37, locationId: 'loc_waves', icon: '🐕‍🦺', armorPierce: 10),

  // --- LOKACJA 4: DOLINA KOŃCA (loc_valley) ---
  EnemyTemplate(id: 'e_valley_1', name: 'Biały Klon Zetsu', baseHp: 350, baseAtk: 46, locationId: 'loc_valley', icon: '⚪'),
  EnemyTemplate(id: 'e_valley_2', name: 'Zbuntowany Chūnin Cienia', baseHp: 380, baseAtk: 50, locationId: 'loc_valley', icon: '👥', dodgeRate: 14),
  EnemyTemplate(id: 'e_valley_3', name: 'Ognisty Kultysta Przeklętej Pieczęci', baseHp: 340, baseAtk: 55, locationId: 'loc_valley', icon: '🔥', critRate: 14),
  EnemyTemplate(id: 'e_valley_4', name: 'Upadły Szermierz Skały', baseHp: 420, baseAtk: 44, locationId: 'loc_valley', icon: '🪨', flatBlock: 8),
  EnemyTemplate(id: 'e_valley_5', name: 'Służący Orochimaru', baseHp: 360, baseAtk: 52, locationId: 'loc_valley', icon: '🐍'),
  EnemyTemplate(id: 'e_valley_ninken', name: 'Ogar Przeklętej Pieczęci', baseHp: 340, baseAtk: 54, locationId: 'loc_valley', icon: '🐕', critRate: 15),

  // --- LOKACJA 5: KRYJÓWKA AKATSUKI (loc_akatsuki) ---
  EnemyTemplate(id: 'e_akatsuki_1', name: 'Wzmocniony Zmutowany Zetsu', baseHp: 520, baseAtk: 68, locationId: 'loc_akatsuki', icon: '🌱'),
  EnemyTemplate(id: 'e_akatsuki_2', name: 'Piekielna Bojowa Marionetka', baseHp: 560, baseAtk: 72, locationId: 'loc_akatsuki', icon: '🎎', armorPierce: 15),
  EnemyTemplate(id: 'e_akatsuki_3', name: 'Strażnik Pieczęci Pięciu Żywiołów', baseHp: 640, baseAtk: 65, locationId: 'loc_akatsuki', icon: '🛑', flatBlock: 12),
  EnemyTemplate(id: 'e_akatsuki_4', name: 'Nukenin z Czerwonej Chmury', baseHp: 500, baseAtk: 78, locationId: 'loc_akatsuki', icon: '☁️', critRate: 18),
  EnemyTemplate(id: 'e_akatsuki_5', name: 'Fanatyk Jashina', baseHp: 580, baseAtk: 74, locationId: 'loc_akatsuki', icon: '🩸', traits: [BossTrait.bloodEnrage]),
  EnemyTemplate(id: 'e_akatsuki_ninken', name: 'Widmowy Cerber Czakry', baseHp: 510, baseAtk: 76, locationId: 'loc_akatsuki', icon: '🐺', traits: [BossTrait.chakraLeech]),
];

const List<EnemyTemplate> bossesPool = [
  EnemyTemplate(
    id: 'boss_gate',
    name: 'Kapitan Zwiadu Obłoku',
    title: 'Szpieg Błyskawicy',
    baseHp: 240,
    baseAtk: 24,
    locationId: 'loc_gate',
    isBoss: true,
    icon: '⚡',
    dodgeRate: 12,
    traits: [BossTrait.dodgeManiac],
  ),
  EnemyTemplate(
    id: 'boss_forest',
    name: 'Władca Węży Manda (Młody)',
    title: 'Postrach Lasu Śmierci',
    baseHp: 420,
    baseAtk: 35,
    locationId: 'loc_forest',
    isBoss: true,
    icon: '🐍',
    armorPierce: 10,
    traits: [BossTrait.poisonMaster],
  ),
  EnemyTemplate(
    id: 'boss_waves',
    name: 'Zabuza Momochi (Widmo Mgły)',
    title: 'Diabeł Ukrytej Mgły',
    baseHp: 600,
    baseAtk: 48,
    locationId: 'loc_waves',
    isBoss: true,
    icon: '🗡️',
    critRate: 15,
    flatBlock: 6,
    traits: [BossTrait.ironSkin, BossTrait.dodgeManiac],
  ),
  EnemyTemplate(
    id: 'boss_valley',
    name: 'Awatar Przeklętej Pieczęci',
    title: 'Uwolniona Forma Poziomu II',
    baseHp: 850,
    baseAtk: 64,
    locationId: 'loc_valley',
    isBoss: true,
    icon: '👹',
    critRate: 15,
    armorPierce: 15,
    traits: [BossTrait.bloodEnrage, BossTrait.ironSkin],
  ),
  EnemyTemplate(
    id: 'boss_akatsuki',
    name: 'Awatar Paina (Ścieżka Asury)',
    title: 'Boski Egzekutor',
    baseHp: 1300,
    baseAtk: 88,
    locationId: 'loc_akatsuki',
    isBoss: true,
    icon: '👁️',
    critRate: 18,
    armorPierce: 20,
    flatBlock: 10,
    traits: [BossTrait.ironSkin, BossTrait.chakraThorns],
  ),
];

const List<DungeonBoss> dungeonBossesPool = [
  DungeonBoss(
    id: 'd_kyubi',
    name: 'Duch Dziewięcioogoniastego (Kyūbi)',
    title: 'Inkarancja Płonącej Nienawiści',
    minLevel: 15,
    baseHp: 1200,
    baseAtk: 62,
    setGroup: 'boss_kyubi',
    icon: '🦊',
  ),
  DungeonBoss(
    id: 'd_susanoo',
    name: 'Pancerne Widmo Susanoo',
    title: 'Niezniszczalna Zbroja Pradawnego Klanu',
    minLevel: 28,
    baseHp: 2400,
    baseAtk: 88,
    setGroup: 'boss_susanoo',
    icon: '🛡️',
  ),
  DungeonBoss(
    id: 'd_kaguya',
    name: 'Projekcja Bogini Królików',
    title: 'Źródło Wszelkiej Czakry',
    minLevel: 42,
    baseHp: 4200,
    baseAtk: 125,
    setGroup: 'boss_kaguya',
    icon: '🌕',
  ),
];

const List<GearArchetype> bossExclusiveSetsPool = [
  GearArchetype(baseName: 'Pazur Płonącego Lisa', slot: GearSlot.weapon, baseStat: 36, setGroup: 'boss_kyubi', icon: '🗡️'),
  GearArchetype(baseName: 'Karmazynowy Płaszcz Czakry', slot: GearSlot.armor, baseStat: 34, setGroup: 'boss_kyubi', icon: '🥋'),
  GearArchetype(baseName: 'Ognista Maska Bestii', slot: GearSlot.helmet, baseStat: 32, setGroup: 'boss_kyubi', icon: '👺'),
  GearArchetype(baseName: 'Sandały Pustynnego Lisa', slot: GearSlot.boots, baseStat: 30, setGroup: 'boss_kyubi', icon: '🥾'),
  GearArchetype(baseName: 'Pieczęć Dziewięciu Ogonów', slot: GearSlot.trinket, baseStat: 28, setGroup: 'boss_kyubi', icon: '📿'),

  GearArchetype(baseName: 'Ostrze Totsuka Susanoo', slot: GearSlot.weapon, baseStat: 52, setGroup: 'boss_susanoo', icon: '🗡️'),
  GearArchetype(baseName: 'Pancerz Duchowego Giganta', slot: GearSlot.armor, baseStat: 56, setGroup: 'boss_susanoo', icon: '🥋'),
  GearArchetype(baseName: 'Hełm Wojownika Tengu', slot: GearSlot.helmet, baseStat: 48, setGroup: 'boss_susanoo', icon: '🛡️'),
  GearArchetype(baseName: 'Masywne Nagolenniki Widma', slot: GearSlot.boots, baseStat: 48, setGroup: 'boss_susanoo', icon: '🥾'),
  GearArchetype(baseName: 'Zwierciadło Yata', slot: GearSlot.trinket, baseStat: 42, setGroup: 'boss_susanoo', icon: '📿'),

  GearArchetype(baseName: 'Kość Popiołu Wszechogarniającego', slot: GearSlot.weapon, baseStat: 74, setGroup: 'boss_kaguya', icon: '🗡️'),
  GearArchetype(baseName: 'Szata Wymiarów Protoplastki', slot: GearSlot.armor, baseStat: 72, setGroup: 'boss_kaguya', icon: '🥋'),
  GearArchetype(baseName: 'Diadem Trzeciego Oka Bogini', slot: GearSlot.helmet, baseStat: 68, setGroup: 'boss_kaguya', icon: '👑'),
  GearArchetype(baseName: 'Gwiezdne Trzewiki Otsutsuki', slot: GearSlot.boots, baseStat: 66, setGroup: 'boss_kaguya', icon: '🥾'),
  GearArchetype(baseName: 'Kula Prawdy Pustki', slot: GearSlot.trinket, baseStat: 60, setGroup: 'boss_kaguya', icon: '🔮'),
];

const List<GearArchetype> standardArchetypesPool = [
  GearArchetype(baseName: 'Kunai Bojowy', slot: GearSlot.weapon, baseStat: 8, icon: '🗡️'),
  GearArchetype(baseName: 'Katana ANBU', slot: GearSlot.weapon, baseStat: 14, setGroup: 'anbu', icon: '🗡️'),
  GearArchetype(baseName: 'Topór Górskich Zbójów', slot: GearSlot.weapon, baseStat: 12, icon: '🪓'),
  GearArchetype(baseName: 'Kosa Żniwiarza', slot: GearSlot.weapon, baseStat: 18, icon: '🗡️'),
  GearArchetype(baseName: 'Kostur Mędrca', slot: GearSlot.weapon, baseStat: 22, setGroup: 'myoboku', icon: '🪄'),

  GearArchetype(baseName: 'Kamizelka Taktyczna Genina', slot: GearSlot.armor, baseStat: 6, icon: '🥋'),
  GearArchetype(baseName: 'Kamizelka Operacyjna ANBU', slot: GearSlot.armor, baseStat: 12, setGroup: 'anbu', icon: '🥋'),
  GearArchetype(baseName: 'Pancerz Bojowy Jonina', slot: GearSlot.armor, baseStat: 16, icon: '🥋'),
  GearArchetype(baseName: 'Płaszcz Ropuchego Mędrca', slot: GearSlot.armor, baseStat: 20, setGroup: 'myoboku', icon: '🥋'),

  GearArchetype(baseName: 'Ochraniacz Czoła', slot: GearSlot.helmet, baseStat: 5, icon: '🛡️'),
  GearArchetype(baseName: 'Maska Porcelanowa ANBU', slot: GearSlot.helmet, baseStat: 10, setGroup: 'anbu', icon: '👺'),
  GearArchetype(baseName: 'Hełm Żelaznej Woli', slot: GearSlot.helmet, baseStat: 14, icon: '👑'),
  GearArchetype(baseName: 'Opaska Ropuchej Góry', slot: GearSlot.helmet, baseStat: 18, setGroup: 'myoboku', icon: '🛡️'),

  GearArchetype(baseName: 'Standardowe Sandały Shinobi', slot: GearSlot.boots, baseStat: 5, icon: '🥾'),
  GearArchetype(baseName: 'Wyciszone Buty ANBU', slot: GearSlot.boots, baseStat: 10, setGroup: 'anbu', icon: '🥾'),
  GearArchetype(baseName: 'Ciężkie Nagolenniki Iwa', slot: GearSlot.boots, baseStat: 14, icon: '🥾'),
  GearArchetype(baseName: 'Kamasze Pustelnika', slot: GearSlot.boots, baseStat: 18, setGroup: 'myoboku', icon: '🥾'),

  GearArchetype(baseName: 'Wisiorek z Jadeitu', slot: GearSlot.trinket, baseStat: 8, icon: '📿'),
  GearArchetype(baseName: 'Amulet Cienia ANBU', slot: GearSlot.trinket, baseStat: 14, setGroup: 'anbu', icon: '📿'),
  GearArchetype(baseName: 'Kryształ Pierwszego Hokage', slot: GearSlot.trinket, baseStat: 22, icon: '💎'),
  GearArchetype(baseName: 'Naszyjnik Myoboku', slot: GearSlot.trinket, baseStat: 26, setGroup: 'myoboku', icon: '📿'),
];

const List<Jutsu> allJutsuPool = [
  Jutsu(
    id: 'j_bunshin',
    name: 'Bunshin no Jutsu',
    chakraCost: 10,
    powerMultiplier: 1.3,
    type: JutsuType.damage,
    effectValue: 0,
    effectDescription: 'Atak klonem wprowadzający zamieszanie.',
    costRyo: 0,
    minRankIndex: 0,
    color: Color(0xFF90A4AE),
  ),
  Jutsu(
    id: 'j_goukakyuu',
    name: 'Katon: Gōkakyū no Jutsu',
    chakraCost: 20,
    powerMultiplier: 1.7,
    type: JutsuType.damage,
    effectValue: 0,
    effectDescription: 'Kula ognia pochłaniająca cel.',
    costRyo: 120,
    minRankIndex: 1,
    color: Color(0xFFFF7043),
  ),
  Jutsu(
    id: 'j_mizu',
    name: 'Suiton: Mizurappa',
    chakraCost: 18,
    powerMultiplier: 1.6,
    type: JutsuType.damage,
    effectValue: 0,
    effectDescription: 'Gwałtowny strumień wody.',
    costRyo: 110,
    minRankIndex: 1,
    color: Color(0xFF42A5F5),
  ),
  Jutsu(
    id: 'j_shousen',
    name: 'Shōsen Jutsu (Leczenie)',
    chakraCost: 25,
    powerMultiplier: 0.0,
    type: JutsuType.healing,
    effectValue: 35,
    effectDescription: 'Medyczna czakra przywracająca 35% HP.',
    costRyo: 160,
    minRankIndex: 1,
    color: Color(0xFF66BB6A),
  ),
  Jutsu(
    id: 'j_doryuheki',
    name: 'Doton: Doryūheki (Mur)',
    chakraCost: 25,
    powerMultiplier: 0.0,
    type: JutsuType.shield,
    effectValue: 24,
    effectDescription: 'Błotny mur dający +24 tymczasowej obrony.',
    costRyo: 180,
    minRankIndex: 2,
    color: Color(0xFF8D6E63),
  ),
  Jutsu(
    id: 'j_chidori',
    name: 'Chidori (Tysiąc Ptaków)',
    chakraCost: 40,
    powerMultiplier: 2.5,
    type: JutsuType.damage,
    effectValue: 0,
    effectDescription: 'Pchnięcie błyskawicy przebijające pancerz.',
    costRyo: 350,
    minRankIndex: 3,
    color: Color(0xFF29B6F6),
  ),
  Jutsu(
    id: 'j_rasengan',
    name: 'Rasengan (Wirująca Sfera)',
    chakraCost: 45,
    powerMultiplier: 2.7,
    type: JutsuType.damage,
    effectValue: 0,
    effectDescription: 'Potężna skondensowana wirująca sfera czakry.',
    costRyo: 420,
    minRankIndex: 3,
    color: Color(0xFF00E5FF),
  ),
  Jutsu(
    id: 'j_kage_shuriken',
    name: 'Kage Shuriken no Jutsu',
    chakraCost: 30,
    powerMultiplier: 0.8,
    type: JutsuType.stun,
    effectValue: 1,
    effectDescription: 'Cień Shurikena paraliżujący ruch wroga na 1 turę.',
    costRyo: 280,
    minRankIndex: 2,
    color: Color(0xFF78909C),
  ),
  Jutsu(
    id: 'j_byakugo',
    name: 'Sōzō Saisei: Byakugō',
    chakraCost: 65,
    powerMultiplier: 0.0,
    type: JutsuType.healing,
    effectValue: 70,
    effectDescription: 'Mitotyczna regeneracja. Przywraca 70% HP (100% gdy < 20% HP).',
    costRyo: 800,
    minRankIndex: 5,
    color: Color(0xFFEC407A),
  ),
  Jutsu(
    id: 'j_kirin',
    name: 'Kirin (Grom Niebios)',
    chakraCost: 75,
    powerMultiplier: 3.8,
    type: JutsuType.damage,
    effectValue: 0,
    effectDescription: 'Naturalny piorun spadający prosto z nieba.',
    costRyo: 950,
    minRankIndex: 5,
    availableInVillage: false,
    color: Color(0xFF7E57C2),
  ),
];

const List<Consumable> allConsumables = [
  Consumable(
    id: 'c_pill',
    name: 'Pigułka Żywnościowa',
    type: ConsumableType.healCpPercent,
    value: 50,
    price: 30,
    description: 'Przywraca 50% czakry.',
    statBonusText: '+50% CP',
    icon: '💊',
  ),
  Consumable(
    id: 'c_dango',
    name: 'Słodkie Dango',
    type: ConsumableType.healHpPercent,
    value: 40,
    price: 25,
    description: 'Tradycyjny przysmak przywracający 40% zdrowia.',
    statBonusText: '+40% HP',
    icon: '🍡',
  ),
  Consumable(
    id: 'c_bandage',
    name: 'Opatrunek Polowy',
    type: ConsumableType.healHpPercent,
    value: 25,
    price: 15,
    description: 'Tamuje krwawienie i leczy 25% HP.',
    statBonusText: '+25% HP',
    icon: '🩹',
  ),
  Consumable(
    id: 'c_ramen',
    name: 'Misoramen u Ichiraku',
    type: ConsumableType.ramenRestore,
    value: 5,
    price: 120,
    description: 'Ciepły posiłek: w pełni odnawia siły i na stałe zwiększa bazowe HP i CP o +5!',
    statBonusText: 'Max HP i CP +5 (Na stałe)',
    icon: '🍜',
  ),
  Consumable(
    id: 'c_smoke',
    name: 'Bomba Dymna',
    type: ConsumableType.smokeEscape,
    value: 1,
    price: 45,
    description: 'Pozwala natychmiast uciec ze zwykłej potyczki w terenie.',
    statBonusText: 'Gwarantowana Ucieczka',
    icon: '💨',
  ),
  Consumable(
    id: 'c_kibaku',
    name: 'Kibaku Fuda (Pieczęć Wybuchowa)',
    type: ConsumableType.directDmg,
    value: 40,
    price: 35,
    description: 'Zadaje bezpośrednie obrażenia obszarowe wybuchem.',
    statBonusText: 'Obrażenia wybuchem',
    icon: '💥',
  ),
];

const List<ShinobiExam> shinobiExams = [
  ShinobiExam(
    targetRankIndex: 1,
    rankTitle: 'Genin',
    requiredLevel: 4,
    examinerName: 'Iruka Umino',
    examinerTitle: 'Instruktor Akademii',
    hp: 140,
    atk: 14,
    critRate: 8,
    dodgeRate: 8,
    icon: '🧑🏻‍🏫',
  ),
  ShinobiExam(
    targetRankIndex: 2,
    rankTitle: 'Chūnin',
    requiredLevel: 12,
    examinerName: 'Ibiki Morino',
    examinerTitle: 'Dowódca Wydziału Tortur',
    hp: 340,
    atk: 30,
    critRate: 12,
    dodgeRate: 10,
    icon: '🕵🏻‍♂️',
  ),
  ShinobiExam(
    targetRankIndex: 3,
    rankTitle: 'Tokubetsu Jōnin',
    requiredLevel: 22,
    examinerName: 'Anko Mitarashi',
    examinerTitle: 'Egzaminator Lasu Śmierci',
    hp: 680,
    atk: 50,
    critRate: 15,
    dodgeRate: 15,
    icon: '🐍',
  ),
  ShinobiExam(
    targetRankIndex: 4,
    rankTitle: 'Jōnin Bojowy',
    requiredLevel: 35,
    examinerName: 'Kakashi Hatake',
    examinerTitle: 'Kopiujący Ninja',
    hp: 1200,
    atk: 75,
    critRate: 20,
    dodgeRate: 20,
    icon: '⚡',
  ),
  ShinobiExam(
    targetRankIndex: 5,
    rankTitle: 'Elita ANBU',
    requiredLevel: 48,
    examinerName: 'Danzō Shimura',
    examinerTitle: 'Lider Korzenia',
    hp: 2100,
    atk: 105,
    critRate: 22,
    dodgeRate: 20,
    icon: '🦯',
  ),
  ShinobiExam(
    targetRankIndex: 6,
    rankTitle: 'Legendarny Sannin / Kage',
    requiredLevel: 60,
    examinerName: 'Hiruzen Sarutobi',
    examinerTitle: 'Trzeci Hokage (Profesor)',
    hp: 3400,
    atk: 145,
    critRate: 25,
    dodgeRate: 22,
    icon: '👴🏻',
  ),
];

const List<Mission> allMissionsPool = [
  // --- Zlecenia: Brama Główna (loc_gate) ---
  Mission(
    id: 'm_gate_1',
    title: 'Oczyszczanie Traktu Kupieckiego',
    desc: 'Pokonaj 3 Bandziorów grasujących przy bramie.',
    rank: 'D',
    minRankIndex: 0,
    locationId: 'loc_gate',
    type: MissionType.killCount,
    targetEnemyId: 'e_gate_1',
    requiredCount: 3,
    rewardRyo: 60,
    rewardExp: 50,
  ),
  Mission(
    id: 'm_gate_2',
    title: 'Polowanie na Zwiadowcę Obłoku',
    desc: 'Wytrop i zneutralizuj wrogiego dowódcę szpiegów.',
    rank: 'C',
    minRankIndex: 1,
    locationId: 'loc_gate',
    type: MissionType.bossHunt,
    targetEnemyId: 'boss_gate',
    requiredCount: 1,
    rewardRyo: 150,
    rewardExp: 140,
  ),
  Mission(
    id: 'm_gate_3',
    title: 'Dostawa Rudy Żelaza',
    desc: 'Przynieś 3 sztuki rudy żelaza dla kowala.',
    rank: 'D',
    minRankIndex: 0,
    locationId: 'loc_gate',
    type: MissionType.itemSupply,
    supplyItemId: matIronOre,
    requiredCount: 3,
    rewardRyo: 80,
    rewardExp: 60,
  ),

  // --- Zlecenia: Las Śmierci (loc_forest) ---
  Mission(
    id: 'm_forest_1',
    title: 'Tępienie Toksycznych Pijawek',
    desc: 'Wyeliminuj 3 Wielkie Pijawki Bagienne w głębi lasu.',
    rank: 'C',
    minRankIndex: 1,
    locationId: 'loc_forest',
    type: MissionType.killCount,
    targetEnemyId: 'e_forest_1',
    requiredCount: 3,
    rewardRyo: 140,
    rewardExp: 130,
  ),
  Mission(
    id: 'm_forest_2',
    title: 'Pacyfikacja Władcy Węży',
    desc: 'Pokonaj Młodego Mandę zagrażającego egzaminowanym.',
    rank: 'B',
    minRankIndex: 2,
    locationId: 'loc_forest',
    type: MissionType.bossHunt,
    targetEnemyId: 'boss_forest',
    requiredCount: 1,
    rewardRyo: 300,
    rewardExp: 280,
  ),

  // --- Zlecenia: Kraj Fali (loc_waves) ---
  Mission(
    id: 'm_waves_1',
    title: 'Rozbicie Najemników Gatō',
    desc: 'Pokonaj 4 najemników na mostach Kraju Fali.',
    rank: 'B',
    minRankIndex: 2,
    locationId: 'loc_waves',
    type: MissionType.killCount,
    targetEnemyId: 'e_waves_1',
    requiredCount: 4,
    rewardRyo: 280,
    rewardExp: 260,
  ),
  Mission(
    id: 'm_waves_2',
    title: 'Pojedynek z Diabłem Mgły',
    desc: 'Stań do walki z Zybuzą Momochi i ochroń most.',
    rank: 'A',
    minRankIndex: 3,
    locationId: 'loc_waves',
    type: MissionType.bossHunt,
    targetEnemyId: 'boss_waves',
    requiredCount: 1,
    rewardRyo: 550,
    rewardExp: 500,
  ),

  // --- Zlecenia: Dolina Końca (loc_valley) ---
  Mission(
    id: 'm_valley_1',
    title: 'Likwidacja Klonów Zetsu',
    desc: 'Zniszcz 4 Białe Klony Zetsu zagrażające granicom.',
    rank: 'A',
    minRankIndex: 3,
    locationId: 'loc_valley',
    type: MissionType.killCount,
    targetEnemyId: 'e_valley_1',
    requiredCount: 4,
    rewardRyo: 500,
    rewardExp: 450,
  ),
  Mission(
    id: 'm_valley_2',
    title: 'Zapieczętowanie Przeklętej Formy',
    desc: 'Pokonaj Uwolnionego Awatara Przeklętej Pieczęci.',
    rank: 'S',
    minRankIndex: 4,
    locationId: 'loc_valley',
    type: MissionType.bossHunt,
    targetEnemyId: 'boss_valley',
    requiredCount: 1,
    rewardRyo: 900,
    rewardExp: 850,
  ),

  // --- Zlecenia: Kryjówka Akatsuki (loc_akatsuki) ---
  Mission(
    id: 'm_akatsuki_1',
    title: 'Neutralizacja Zmutowanych Bestii',
    desc: 'Pokonaj 4 zmutowane istoty strzegące wejścia do jaskini.',
    rank: 'S',
    minRankIndex: 5,
    locationId: 'loc_akatsuki',
    type: MissionType.killCount,
    targetEnemyId: 'e_akatsuki_1',
    requiredCount: 4,
    rewardRyo: 1100,
    rewardExp: 1000,
  ),
  Mission(
    id: 'm_akatsuki_2',
    title: 'Starcie z Boskim Awatarem',
    desc: 'Pokonaj Ścieżkę Asury Paina w sercu kryjówki.',
    rank: 'SS',
    minRankIndex: 5,
    locationId: 'loc_akatsuki',
    type: MissionType.bossHunt,
    targetEnemyId: 'boss_akatsuki',
    requiredCount: 1,
    rewardRyo: 2200,
    rewardExp: 2000,
  ),
];
