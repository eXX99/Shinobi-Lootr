import 'dart:math';
import 'package:flutter/material.dart';

enum GearSlot {
  weapon,
  armor,
  helmet,
  boots,
  trinket,
}

enum ItemRarity {
  common,
  rare,
  epic,
  legendary,
}

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
  chakraLeech,
  ironSkin,
  poisonMaster,
  dodgeManiac,
  bloodEnrage,
  chakraThorns,
}

enum EnemyPrefix {
  weak,
  normal,
  strong,
}

enum JutsuType {
  damage,
  healing,
  shield,
  stun,
}

enum ConsumableType {
  healHpPercent,
  healCpPercent,
  ramenRestore,
  buffAtk,
  smokeEscape,
  directDmg,
}

enum MissionType {
  killCount,
  bossHunt,
  itemSupply,
}

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
    description: 'Surowiec do podstawowego kucia (+1 do +3).',
  ),
  matSteel: CraftingMaterialInfo(
    id: matSteel,
    name: 'Stal z Kraju Żelaza',
    icon: '🧱',
    description: 'Twardy stop do zaawansowanego kucia (+4 do +6).',
  ),
  matCrystal: CraftingMaterialInfo(
    id: matCrystal,
    name: 'Kryształ Czakry',
    icon: '💎',
    description: 'Rzadki minerał do legendarnego wzmacniania (+7 do +9).',
  ),
  matDungeonKey: CraftingMaterialInfo(
    id: matDungeonKey,
    name: 'Klucz do Lochów',
    icon: '🗝️',
    description: 'Otwiera wejście do podziemi z bossami.',
  ),
};

class GearAffix {
  final AffixType type;
  final int value;

  const GearAffix({required this.type, required this.value});

  String get label {
    switch (type) {
      case AffixType.critRate: return '+$value% Szansy na Krytyk';
      case AffixType.dodgeRate: return '+$value% Uniku (Kawarimi)';
      case AffixType.armorPierce: return '+$value% Przebicia Pancerza';
      case AffixType.lifeSteal: return '+$value% Kradzieży Życia';
      case AffixType.hpRegen: return '+$value HP na turę';
      case AffixType.chakraRegen: return '+$value CP na turę';
      case AffixType.bonusHp: return '+$value Max HP';
      case AffixType.bonusChakra: return '+$value Max CP';
    }
  }

  Map<String, dynamic> toJson() => {'type': type.index, 'value': value};

  factory GearAffix.fromJson(Map<String, dynamic> json) => GearAffix(
        type: AffixType.values[json['type'] as int],
        value: json['value'] as int,
      );
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
    required this.icon,
  });

  int get effectiveStat => baseStat + (upgradeLevel * (rarity.index + 2));

  String get displayName => upgradeLevel > 0 ? '$name (+$upgradeLevel)' : name;

  bool get isBossSet => setGroup.startsWith('boss_');

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
      case ItemRarity.common: return const Color(0xFFCFD8DC);
      case ItemRarity.rare: return const Color(0xFF42A5F5);
      case ItemRarity.epic: return const Color(0xFFAB47BC);
      case ItemRarity.legendary: return const Color(0xFFFFB300);
    }
  }

  Color get borderColor => isBossSet ? const Color(0xFFFF1744) : color;
  double get borderWidth => isBossSet ? 2.2 : (rarity == ItemRarity.legendary ? 1.8 : 1.2);

  int getAffixValue(AffixType type) {
    int total = 0;
    for (var a in affixes) {
      if (a.type == type) total += a.value;
    }
    return total;
  }

  int get marketValue {
    int mult = rarity.index + 1;
    return (baseStat * 8 * mult) + (upgradeLevel * 40);
  }

  int get sellPrice => max(5, (marketValue * 0.25).round());
  int get merchantSellPrice => max(8, (marketValue * 0.45).round());
  int get sealingCost => max(20, (marketValue * 0.50).round());

  NinjaGear copyWith({
    String? name,
    ItemRarity? rarity,
    GearSlot? slot,
    int? baseStat,
    int? upgradeLevel,
    List<GearAffix>? affixes,
    String? setGroup,
    bool? isSoulbound,
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
        'icon': icon,
      };

  factory NinjaGear.fromJson(Map<String, dynamic> json) => NinjaGear(
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
        icon: json['icon'] as String? ?? '🗡️',
      );
}

class GearArchetype {
  final String baseName;
  final GearSlot slot;
  final int baseStat;
  final String icon;
  final String setGroup;

  const GearArchetype({
    required this.baseName,
    required this.slot,
    required this.baseStat,
    required this.icon,
    this.setGroup = 'none',
  });
}

const List<GearArchetype> standardArchetypesPool = [
  GearArchetype(baseName: 'Kunai Liścia', slot: GearSlot.weapon, baseStat: 14, icon: '🗡️'),
  GearArchetype(baseName: 'Tanto ANBU Cienia', slot: GearSlot.weapon, baseStat: 18, icon: '🗡️', setGroup: 'anbu'),
  GearArchetype(baseName: 'Ostrze Wiatru Myōboku', slot: GearSlot.weapon, baseStat: 22, icon: '🗡️', setGroup: 'myoboku'),
  GearArchetype(baseName: 'Kamizelka Chunina', slot: GearSlot.armor, baseStat: 12, icon: '🥋'),
  GearArchetype(baseName: 'Pancerz Skrytobójcy ANBU', slot: GearSlot.armor, baseStat: 16, icon: '🥋', setGroup: 'anbu'),
  GearArchetype(baseName: 'Szata Ropuszego Mędrca', slot: GearSlot.armor, baseStat: 20, icon: '🥋', setGroup: 'myoboku'),
  GearArchetype(baseName: 'Ochraniacz Czoła', slot: GearSlot.helmet, baseStat: 8, icon: '🛡️'),
  GearArchetype(baseName: 'Maska Lisa ANBU', slot: GearSlot.helmet, baseStat: 12, icon: '🦊', setGroup: 'anbu'),
  GearArchetype(baseName: 'Opaska Trybu Mędrca', slot: GearSlot.helmet, baseStat: 15, icon: '👑', setGroup: 'myoboku'),
  GearArchetype(baseName: 'Sandały Shinobi', slot: GearSlot.boots, baseStat: 8, icon: '🥾'),
  GearArchetype(baseName: 'Ciche Trzewiki ANBU', slot: GearSlot.boots, baseStat: 12, icon: '🥾', setGroup: 'anbu'),
  GearArchetype(baseName: 'Kamasze Żabiej Zwinności', slot: GearSlot.boots, baseStat: 15, icon: '🥾', setGroup: 'myoboku'),
  GearArchetype(baseName: 'Amulet Przepływu Czakry', slot: GearSlot.trinket, baseStat: 10, icon: '📿'),
  GearArchetype(baseName: 'Pieczęć Operacyjna ANBU', slot: GearSlot.trinket, baseStat: 15, icon: '📿', setGroup: 'anbu'),
  GearArchetype(baseName: 'Wisiorek Kamienia Myōboku', slot: GearSlot.trinket, baseStat: 20, icon: '📿', setGroup: 'myoboku'),
];

const List<GearArchetype> bossExclusiveSetsPool = [
  GearArchetype(baseName: 'Pazur Lisa Kyūbi', slot: GearSlot.weapon, baseStat: 35, icon: '🦊', setGroup: 'boss_kyubi'),
  GearArchetype(baseName: 'Płaszcz Szkarłatnej Bestii', slot: GearSlot.armor, baseStat: 30, icon: '🥋', setGroup: 'boss_kyubi'),
  GearArchetype(baseName: 'Ostrze Totsuka Susanoo', slot: GearSlot.weapon, baseStat: 40, icon: '🗡️', setGroup: 'boss_susanoo'),
  GearArchetype(baseName: 'Żebro Niematerialnego Pancerza', slot: GearSlot.armor, baseStat: 36, icon: '🛡️', setGroup: 'boss_susanoo'),
  GearArchetype(baseName: 'Szata Boskiego Drzewa Kaguya', slot: GearSlot.armor, baseStat: 45, icon: '👑', setGroup: 'boss_kaguya'),
  GearArchetype(baseName: 'Klejnot Rinne Sharingana', slot: GearSlot.trinket, baseStat: 35, icon: '👁️', setGroup: 'boss_kaguya'),
];

class Jutsu {
  final String id;
  final String name;
  final JutsuType type;
  final int chakraCost;
  final double powerMultiplier;
  final int effectValue;
  final String effectDescription;
  final int costRyo;
  final int minRankIndex;
  final Color color;
  final bool availableInVillage;

  const Jutsu({
    required this.id,
    required this.name,
    required this.type,
    required this.chakraCost,
    this.powerMultiplier = 1.0,
    this.effectValue = 0,
    required this.effectDescription,
    required this.costRyo,
    required this.minRankIndex,
    required this.color,
    this.availableInVillage = true,
  });

  Map<String, dynamic> toJson() => {'id': id};

  factory Jutsu.fromJson(Map<String, dynamic> json) {
    final String id = json['id'] as String;
    return allJutsuPool.firstWhere((j) => j.id == id, orElse: () => allJutsuPool[0]);
  }
}

const List<Jutsu> allJutsuPool = [
  Jutsu(
    id: 'j_basic_tai',
    name: 'Seria Ciosów Wręcz',
    type: JutsuType.damage,
    chakraCost: 10,
    powerMultiplier: 1.2,
    effectDescription: 'Szybkie uderzenie podstawowe Taijutsu.',
    costRyo: 50,
    minRankIndex: 0,
    color: Color(0xFFFFB74D),
  ),
  Jutsu(
    id: 'j_katon_fireball',
    name: 'Katon: Kula Ognia',
    type: JutsuType.damage,
    chakraCost: 25,
    powerMultiplier: 2.0,
    effectDescription: 'Silny płomień wypalający pancerz wroga.',
    costRyo: 200,
    minRankIndex: 1,
    color: Color(0xFFFF7043),
  ),
  Jutsu(
    id: 'j_suiton_water',
    name: 'Suiton: Wodny Pocisk',
    type: JutsuType.damage,
    chakraCost: 22,
    powerMultiplier: 1.9,
    effectDescription: 'Sprężony strumień wody z dużą siłą uderzenia.',
    costRyo: 180,
    minRankIndex: 1,
    color: Color(0xFF42A5F5),
  ),
  Jutsu(
    id: 'j_heal_palm',
    name: 'Iryōnin: Uleczenie Dłoni',
    type: JutsuType.healing,
    chakraCost: 28,
    effectValue: 35,
    effectDescription: 'Leczy 35% Twojego maksymalnego zdrowia.',
    costRyo: 250,
    minRankIndex: 1,
    color: Color(0xFF66BB6A),
  ),
  Jutsu(
    id: 'j_doton_wall',
    name: 'Doton: Błotny Mur Obronny',
    type: JutsuType.shield,
    chakraCost: 25,
    effectValue: 20,
    effectDescription: 'Wznosi kamienną ścianę dającą +20 obrony na turę.',
    costRyo: 240,
    minRankIndex: 2,
    color: Color(0xFF8D6E63),
  ),
  Jutsu(
    id: 'j_chidori',
    name: 'Raiton: Chidori (Ostrze Błyskawicy)',
    type: JutsuType.damage,
    chakraCost: 45,
    powerMultiplier: 3.2,
    effectDescription: 'Błyskawiczne pchnięcie omijające część obrony.',
    costRyo: 600,
    minRankIndex: 2,
    color: Color(0xFF29B6F6),
  ),
  Jutsu(
    id: 'j_rasengan',
    name: 'Ninjutsu: Wirujący Rasengan',
    type: JutsuType.damage,
    chakraCost: 45,
    powerMultiplier: 3.3,
    effectDescription: 'Czysta skondensowana sfera czakry.',
    costRyo: 650,
    minRankIndex: 2,
    color: Color(0xFF00E5FF),
  ),
  Jutsu(
    id: 'j_wire_trap',
    name: 'Kawarimi: Druty Wiążące',
    type: JutsuType.stun,
    chakraCost: 35,
    effectValue: 1,
    effectDescription: 'Ogłusza przeciwnika na 1 turę.',
    costRyo: 500,
    minRankIndex: 2,
    color: Color(0xFFB0BEC5),
  ),
  Jutsu(
    id: 'j_dragon_fire',
    name: 'Katon: Smoczy Płomień',
    type: JutsuType.damage,
    chakraCost: 65,
    powerMultiplier: 4.2,
    effectDescription: 'Potężny płomień niszczący wroga.',
    costRyo: 1400,
    minRankIndex: 3,
    color: Color(0xFFE64A19),
  ),
  Jutsu(
    id: 'j_byakugo',
    name: 'Fūinjutsu: Siła Stu (Byakugō)',
    type: JutsuType.healing,
    chakraCost: 75,
    effectValue: 60,
    effectDescription: 'Natychmiast przywraca 60% HP (lub 100% gdy <20% HP).',
    costRyo: 2200,
    minRankIndex: 4,
    color: Color(0xFF2E7D32),
  ),
  Jutsu(
    id: 'j_rasenshuriken',
    name: 'Fūton: Rasenshuriken',
    type: JutsuType.damage,
    chakraCost: 95,
    powerMultiplier: 6.0,
    effectDescription: 'Legendarna nawałnica mikroigieł wiatru.',
    costRyo: 3500,
    minRankIndex: 5,
    color: Color(0xFF00B0FF),
  ),
  Jutsu(
    id: 'j_kirin',
    name: 'Raiton: Kirin Rycząca Bestia',
    type: JutsuType.damage,
    chakraCost: 90,
    powerMultiplier: 5.8,
    effectDescription: 'Prawdziwy piorun z niebios omijający pancerz.',
    costRyo: 3200,
    minRankIndex: 5,
    color: Color(0xFFFFD600),
  ),
  Jutsu(
    id: 'j_secret_amaterasu',
    name: 'Kinjutsu: Czarne Płomienie Amaterasu',
    type: JutsuType.damage,
    chakraCost: 110,
    powerMultiplier: 7.2,
    effectDescription: 'Sekret Mędrca: Wieczny płomień trawiący wroga.',
    costRyo: 4000,
    minRankIndex: 4,
    color: Color(0xFF212121),
    availableInVillage: false,
  ),
];

class Consumable {
  final String id;
  final String name;
  final String icon;
  final ConsumableType type;
  final int value;
  final int price;
  final String description;
  final String statBonusText;

  const Consumable({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    required this.value,
    required this.price,
    required this.description,
    required this.statBonusText,
  });
}

const List<Consumable> allConsumables = [
  Consumable(
    id: 'c_pill',
    name: 'Pigułka Żywnościowa',
    icon: '💊',
    type: ConsumableType.healHpPercent,
    value: 40,
    price: 35,
    description: 'Błyskawicznie regeneruje 40% maksymalnego HP.',
    statBonusText: '+40% Max HP',
  ),
  Consumable(
    id: 'c_dango',
    name: 'Słodkie Dango Czakry',
    icon: '🍡',
    type: ConsumableType.healCpPercent,
    value: 50,
    price: 30,
    description: 'Przywraca 50% Twojej maksymalnej czakry.',
    statBonusText: '+50% Max CP',
  ),
  Consumable(
    id: 'c_bandage',
    name: 'Opatrunek Polowy',
    icon: '🩹',
    type: ConsumableType.healHpPercent,
    value: 25,
    price: 20,
    description: 'Podstawowe bandaże tamujące krew.',
    statBonusText: '+25% Max HP',
  ),
  Consumable(
    id: 'c_ramen',
    name: 'Ramen Ichiraku (Specjał)',
    icon: '🍜',
    type: ConsumableType.ramenRestore,
    value: 5,
    price: 180,
    description: 'Trwale zwiększa bazowe HP i CP o +5 punktów!',
    statBonusText: '+5 Baza HP & CP',
  ),
  Consumable(
    id: 'c_soldier_pill',
    name: 'Pigułka Bojowa Akimichi',
    icon: '🔴',
    type: ConsumableType.buffAtk,
    value: 1,
    price: 150,
    description: 'Trwale zwiększa bazowy atak ninja o +1 punkt.',
    statBonusText: '+1 Baza Ataku',
  ),
  Consumable(
    id: 'c_smoke',
    name: 'Bomba Dymna',
    icon: '💨',
    type: ConsumableType.smokeEscape,
    value: 0,
    price: 45,
    description: 'Pozwala natychmiast uciec z normalnego starcia.',
    statBonusText: 'Pewna ucieczka',
  ),
  Consumable(
    id: 'c_kibaku',
    name: 'Pieczęć Wybuchowa (Kibakufuda)',
    icon: '💥',
    type: ConsumableType.directDmg,
    value: 40,
    price: 50,
    description: 'Zadaje bezpośrednie obrażenia wrogowi w walce.',
    statBonusText: '~40+ pkt obrażeń',
  ),
];

class ShinobiLocation {
  final String id;
  final String name;
  final String icon;
  final int minLevel;
  final String description;

  const ShinobiLocation({
    required this.id,
    required this.name,
    required this.icon,
    required this.minLevel,
    required this.description,
  });
}

const List<ShinobiLocation> shinobiLocations = [
  ShinobiLocation(
    id: 'loc_gate',
    name: 'Brama Wioski Liścia',
    icon: '⛩️',
    minLevel: 1,
    description: 'Obrzeża lasu wokół Konohy. Dzikie psy i zbiegowie.',
  ),
  ShinobiLocation(
    id: 'loc_forest',
    name: 'Las Śmierci (Egzamin Chūnina)',
    icon: '🌲',
    minLevel: 8,
    description: 'Gęsty, wilgotny las pełen drapieżników i wrogich drużyn.',
  ),
  ShinobiLocation(
    id: 'loc_waves',
    name: 'Wielki Most Narudo (Kraj Fali)',
    icon: '🌉',
    minLevel: 18,
    description: 'Most we mgle patrolujący przez bezwzględnych zabójców z Kirigakure.',
  ),
  ShinobiLocation(
    id: 'loc_valley',
    name: 'Dolina Końca',
    icon: '🗿',
    minLevel: 30,
    description: 'Miejsce legendarnych pojedynków przy zniszczonych pomnikach.',
  ),
  ShinobiLocation(
    id: 'loc_akatsuki',
    name: 'Kryjówka Akatsuki',
    icon: '☁️',
    minLevel: 45,
    description: 'Tajemna baza elity Nukeninów polujących na ogoniaste bestie.',
  ),
];

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
    this.title = 'Przeciwnik',
    required this.baseHp,
    required this.baseAtk,
    required this.locationId,
    this.isBoss = false,
    required this.icon,
    this.critRate = 5,
    this.dodgeRate = 5,
    this.armorPierce = 0,
    this.flatBlock = 0,
    this.traits = const [],
  });

  double get powerRating => (baseHp * 0.4) + (baseAtk * 1.5);
}

const List<EnemyTemplate> standardEnemiesPool = [
  EnemyTemplate(id: 'en_dog', name: 'Dziki Pies Czakry', baseHp: 55, baseAtk: 11, locationId: 'loc_gate', icon: '🐕'),
  EnemyTemplate(id: 'en_bandit', name: 'Złodziej Zwojów', baseHp: 75, baseAtk: 14, locationId: 'loc_gate', icon: '🥷'),
  EnemyTemplate(id: 'en_scout', name: 'Zwiadowca z Trawy', baseHp: 90, baseAtk: 17, locationId: 'loc_gate', icon: '👤'),
  EnemyTemplate(id: 'en_leech', name: 'Pijawka Czakry', baseHp: 130, baseAtk: 24, locationId: 'loc_forest', icon: '🐛', traits: [BossTrait.chakraLeech]),
  EnemyTemplate(id: 'en_rain_genin', name: 'Genin Ukrytego Deszczu', baseHp: 160, baseAtk: 28, locationId: 'loc_forest', icon: '🌧️'),
  EnemyTemplate(id: 'en_snake', name: 'Wielki Wąż Lasu Śmierci', baseHp: 210, baseAtk: 34, locationId: 'loc_forest', icon: '🐍', traits: [BossTrait.poisonMaster]),
  EnemyTemplate(id: 'en_thug', name: 'Najemnik Gato', baseHp: 250, baseAtk: 42, locationId: 'loc_waves', icon: '🗡️'),
  EnemyTemplate(id: 'en_hunter', name: 'Tropiciel Kirigakure (ANBU)', baseHp: 310, baseAtk: 50, locationId: 'loc_waves', icon: '🎭', traits: [BossTrait.dodgeManiac]),
  EnemyTemplate(id: 'en_curse_bearer', name: 'Nosiciel Przeklętej Pieczęci', baseHp: 440, baseAtk: 66, locationId: 'loc_valley', icon: '👿', traits: [BossTrait.bloodEnrage]),
  EnemyTemplate(id: 'en_sound_four', name: 'Strażnik Czwórki Dźwięku', baseHp: 510, baseAtk: 74, locationId: 'loc_valley', icon: '🥁', traits: [BossTrait.ironSkin]),
  EnemyTemplate(id: 'en_zetsu', name: 'Armia Białych Zetsu', baseHp: 680, baseAtk: 92, locationId: 'loc_akatsuki', icon: '🌱', traits: [BossTrait.chakraLeech, BossTrait.dodgeManiac]),
  EnemyTemplate(id: 'en_puppet', name: 'Zbiegły Lalkarz Piasku', baseHp: 800, baseAtk: 105, locationId: 'loc_akatsuki', icon: '🪵', traits: [BossTrait.poisonMaster]),
];

const List<EnemyTemplate> bossesPool = [
  EnemyTemplate(id: 'boss_mizuki', name: 'Mizuki Zdrajca Liścia', title: 'Zbieg z Zwojem Pieczęci', baseHp: 240, baseAtk: 24, locationId: 'loc_gate', isBoss: true, icon: '🥷', traits: [BossTrait.dodgeManiac]),
  EnemyTemplate(id: 'boss_orochimaru_snake', name: 'Zmutowany Wąż Orochimaru', title: 'Monstrum Lasu Śmierci', baseHp: 520, baseAtk: 44, locationId: 'loc_forest', isBoss: true, icon: '🐍', traits: [BossTrait.poisonMaster, BossTrait.ironSkin]),
  EnemyTemplate(id: 'boss_zabuza', name: 'Zabuza Momochi (Demon Mgły)', title: 'Jeden z Siedmiu Mistrzów Miecza', baseHp: 950, baseAtk: 72, locationId: 'loc_waves', isBoss: true, icon: '🗡️', traits: [BossTrait.bloodEnrage, BossTrait.ironSkin]),
  EnemyTemplate(id: 'boss_gaara', name: 'Gaara Pustynnego Piasku', title: 'Demon Shukaku', baseHp: 1500, baseAtk: 96, locationId: 'loc_valley', isBoss: true, icon: '🏺', traits: [BossTrait.ironSkin, BossTrait.chakraThorns]),
  EnemyTemplate(id: 'boss_itachi', name: 'Klon Cienia Itachiego Uchiha', title: 'Mistrz Mangekyō Sharingana', baseHp: 2200, baseAtk: 135, locationId: 'loc_akatsuki', isBoss: true, icon: '👁️', traits: [BossTrait.dodgeManiac, BossTrait.bloodEnrage, BossTrait.chakraThorns]),
];

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

const List<DungeonBoss> dungeonBossesPool = [
  DungeonBoss(
    id: 'db_kyubi',
    name: 'Awatar Kyūbi (Dziewięcioogoniasty)',
    title: 'Manifestacja Czystego Gniewu Lisa',
    minLevel: 20,
    baseHp: 1600,
    baseAtk: 88,
    setGroup: 'boss_kyubi',
    icon: '🦊',
  ),
  DungeonBoss(
    id: 'db_susanoo',
    name: 'Widmowy Susanoo Wojownik',
    title: 'Nieprzenikniony Pancerz Duszy Uchiha',
    minLevel: 32,
    baseHp: 2800,
    baseAtk: 125,
    setGroup: 'boss_susanoo',
    icon: '🛡️',
  ),
  DungeonBoss(
    id: 'db_kaguya',
    name: 'Wspomnienie Księżniczki Kaguyi',
    title: 'Matka Wszelkiej Czakry',
    minLevel: 48,
    baseHp: 4500,
    baseAtk: 175,
    setGroup: 'boss_kaguya',
    icon: '👑',
  ),
];

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

const List<ShinobiExam> shinobiExams = [
  ShinobiExam(
    targetRankIndex: 1,
    rankTitle: 'Genin',
    requiredLevel: 5,
    examinerName: 'Iruka Umino',
    examinerTitle: 'Instruktor Akademii',
    hp: 190,
    atk: 22,
    critRate: 8,
    dodgeRate: 8,
    icon: '🍃',
  ),
  ShinobiExam(
    targetRankIndex: 2,
    rankTitle: 'Chūnin',
    requiredLevel: 13,
    examinerName: 'Baki z Sunagakure',
    examinerTitle: 'Egzaminator Finałowy',
    hp: 480,
    atk: 48,
    critRate: 10,
    dodgeRate: 10,
    icon: '📜',
  ),
  ShinobiExam(
    targetRankIndex: 3,
    rankTitle: 'Tokubetsu Jōnin',
    requiredLevel: 23,
    examinerName: 'Yamato (Mokuton)',
    examinerTitle: 'Kapitan ANBU',
    hp: 920,
    atk: 76,
    critRate: 12,
    dodgeRate: 12,
    icon: '🪵',
  ),
  ShinobiExam(
    targetRankIndex: 4,
    rankTitle: 'Jōnin Bojowy',
    requiredLevel: 36,
    examinerName: 'Kakashi Hatake',
    examinerTitle: 'Ninja Kopiujący',
    hp: 1750,
    atk: 115,
    critRate: 15,
    dodgeRate: 16,
    icon: '⚡',
  ),
  ShinobiExam(
    targetRankIndex: 5,
    rankTitle: 'Elita ANBU (Korzeń)',
    requiredLevel: 49,
    examinerName: 'Danzo Shimura',
    examinerTitle: 'Przywódca Korzenia',
    hp: 2800,
    atk: 155,
    critRate: 18,
    dodgeRate: 15,
    icon: '🎭',
  ),
  ShinobiExam(
    targetRankIndex: 6,
    rankTitle: 'Legendarny Sannin / Kage',
    requiredLevel: 61,
    examinerName: 'Jiraiya (Tryb Mędrca)',
    examinerTitle: 'Ropuszy Mędrzec Góry Myōboku',
    hp: 4200,
    atk: 210,
    critRate: 20,
    dodgeRate: 18,
    icon: '🐸',
  ),
];

class ShinobiMission {
  final String id;
  final String title;
  final String desc;
  final String rank;
  final int minRankIndex;
  final String locationId;
  final MissionType type;
  final String targetEnemyId;
  final int requiredCount;
  final int rewardRyo;
  final int rewardExp;
  final String? supplyItemId;

  const ShinobiMission({
    required this.id,
    required this.title,
    required this.desc,
    required this.rank,
    required this.minRankIndex,
    required this.locationId,
    required this.type,
    this.targetEnemyId = '',
    required this.requiredCount,
    required this.rewardRyo,
    required this.rewardExp,
    this.supplyItemId,
  });
}

const List<ShinobiMission> allMissionsPool = [
  ShinobiMission(
    id: 'm_gate_dogs',
    title: 'Oczyszczenie Przedpola',
    desc: 'Wyeliminuj dzikie psy czakry grasujące pod bramą.',
    rank: 'D',
    minRankIndex: 0,
    locationId: 'loc_gate',
    type: MissionType.killCount,
    targetEnemyId: 'en_dog',
    requiredCount: 3,
    rewardRyo: 60,
    rewardExp: 45,
  ),
  ShinobiMission(
    id: 'm_gate_thief',
    title: 'Kradzież Zwojów',
    desc: 'Pokonaj złodziei zwojów na trakcie handlowym.',
    rank: 'D',
    minRankIndex: 0,
    locationId: 'loc_gate',
    type: MissionType.killCount,
    targetEnemyId: 'en_bandit',
    requiredCount: 3,
    rewardRyo: 85,
    rewardExp: 65,
  ),
  ShinobiMission(
    id: 'm_forest_leeches',
    title: 'Zaraza Pijawek',
    desc: 'Zneutralizuj wielkie pijawki wysysające czakrę z drzew.',
    rank: 'C',
    minRankIndex: 1,
    locationId: 'loc_forest',
    type: MissionType.killCount,
    targetEnemyId: 'en_leech',
    requiredCount: 4,
    rewardRyo: 150,
    rewardExp: 140,
  ),
  ShinobiMission(
    id: 'm_forest_boss',
    title: 'Potwór Lasu Śmierci',
    desc: 'Zgładź Zmutowanego Węża Orochimaru w sercu lasu.',
    rank: 'B',
    minRankIndex: 2,
    locationId: 'loc_forest',
    type: MissionType.bossHunt,
    targetEnemyId: 'boss_orochimaru_snake',
    requiredCount: 1,
    rewardRyo: 400,
    rewardExp: 380,
  ),
  ShinobiMission(
    id: 'm_waves_mercs',
    title: 'Najemnicy z Mgły',
    desc: 'Oczyść Most Narudo z uzbrojonych bandytów Gato.',
    rank: 'B',
    minRankIndex: 2,
    locationId: 'loc_waves',
    type: MissionType.killCount,
    targetEnemyId: 'en_thug',
    requiredCount: 5,
    rewardRyo: 320,
    rewardExp: 310,
  ),
  ShinobiMission(
    id: 'm_waves_zabuza',
    title: 'Demon Ukrytej Mgły',
    desc: 'Pokonaj Zabuzę Momochi na Moście Kraju Fali.',
    rank: 'A',
    minRankIndex: 3,
    locationId: 'loc_waves',
    type: MissionType.bossHunt,
    targetEnemyId: 'boss_zabuza',
    requiredCount: 1,
    rewardRyo: 800,
    rewardExp: 750,
  ),
  ShinobiMission(
    id: 'm_valley_curse',
    title: 'Przeklęte Pieczęcie',
    desc: 'Zlikwiduj nosicieli przeklętej pieczęci w Dolinie Końca.',
    rank: 'A',
    minRankIndex: 4,
    locationId: 'loc_valley',
    type: MissionType.killCount,
    targetEnemyId: 'en_curse_bearer',
    requiredCount: 6,
    rewardRyo: 950,
    rewardExp: 900,
  ),
  ShinobiMission(
    id: 'm_akatsuki_zetsu',
    title: 'Infiltracja Zetsu',
    desc: 'Powstrzymaj armię Białych Zetsu w podziemiach Akatsuki.',
    rank: 'S',
    minRankIndex: 5,
    locationId: 'loc_akatsuki',
    type: MissionType.killCount,
    targetEnemyId: 'en_zetsu',
    requiredCount: 8,
    rewardRyo: 1600,
    rewardExp: 1500,
  ),
];

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'isDefeated': isDefeated,
      };
}

class MilestoneTracker {
  int enemiesSlain;
  int physicalHitsDealt;
  int jutsuCasts;
  int bountiesClaimed;
  int damageTaken;

  MilestoneTracker({
    this.enemiesSlain = 0,
    this.physicalHitsDealt = 0,
    this.jutsuCasts = 0,
    this.bountiesClaimed = 0,
    this.damageTaken = 0,
  });

  Map<String, dynamic> toJson() => {
        'enemiesSlain': enemiesSlain,
        'physicalHitsDealt': physicalHitsDealt,
        'jutsuCasts': jutsuCasts,
        'bountiesClaimed': bountiesClaimed,
        'damageTaken': damageTaken,
      };

  factory MilestoneTracker.fromJson(Map<String, dynamic> json) => MilestoneTracker(
        enemiesSlain: json['enemiesSlain'] as int? ?? 0,
        physicalHitsDealt: json['physicalHitsDealt'] as int? ?? 0,
        jutsuCasts: json['jutsuCasts'] as int? ?? 0,
        bountiesClaimed: json['bountiesClaimed'] as int? ?? 0,
        damageTaken: json['damageTaken'] as int? ?? 0,
      );
}
