import 'package:flutter/material.dart';

enum GearSlot { weapon, armor, helmet, boots, trinket }

enum ItemRarity { common, rare, epic, legendary }

enum AffixType {
  bonusHp,
  bonusChakra,
  critRate,
  dodgeRate,
  armorPierce,
  lifeSteal,
  hpRegen,
  chakraRegen,
}

enum MissionType {
  killCount,
  bossHunt,
  itemSupply,
}

enum EnemyPrefix {
  weak,
  normal,
  strong,
}

class GearAffix {
  final AffixType type;
  final int value;

  const GearAffix({required this.type, required this.value});

  String get label {
    switch (type) {
      case AffixType.bonusHp:
        return '+$value Max HP';
      case AffixType.bonusChakra:
        return '+$value Max CP';
      case AffixType.critRate:
        return '+$value% Szansy na Krytyk';
      case AffixType.dodgeRate:
        return '+$value% Szansy na Kawarimi (Unik)';
      case AffixType.armorPierce:
        return '+$value% Przebicia Pancerza';
      case AffixType.lifeSteal:
        return '+$value% Kradzieży Życia (Lifesteal)';
      case AffixType.hpRegen:
        return '+$value HP regeneracji/turę';
      case AffixType.chakraRegen:
        return '+$value CP regeneracji/turę';
    }
  }

  Map<String, dynamic> toJson() => {'type': type.index, 'value': value};

  factory GearAffix.fromJson(Map<String, dynamic> json) =>
      GearAffix(type: AffixType.values[json['type']], value: json['value']);
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
    this.icon = '🗡️',
  });

  bool get isBossSet => setGroup.startsWith('boss_');

  int get effectiveStat => baseStat + (upgradeLevel * 4);

  int get marketValue {
    int rarityMult = (rarity.index + 1) * 35;
    int affixesVal = affixes.length * 25;
    return rarityMult + (baseStat * 6) + affixesVal;
  }

  int get sellPrice => (marketValue * 0.20).round();
  int get merchantSellPrice => (marketValue * 0.45).round();
  int get sealingCost => (marketValue * 0.85).round();

  String get displayName => upgradeLevel > 0 ? '$name +$upgradeLevel' : name;

  String get rarityLabel {
    switch (rarity) {
      case ItemRarity.common:
        return 'Zwykły';
      case ItemRarity.rare:
        return 'Mistrzowski';
      case ItemRarity.epic:
        return 'Pradawny';
      case ItemRarity.legendary:
        return 'Legendarny';
    }
  }

  Color get color {
    switch (rarity) {
      case ItemRarity.common:
        return const Color(0xFFB0BEC5);
      case ItemRarity.rare:
        return const Color(0xFF42A5F5);
      case ItemRarity.epic:
        return const Color(0xFFAB47BC);
      case ItemRarity.legendary:
        return const Color(0xFFFFB300);
    }
  }

  Color get borderColor => color;

  double get borderWidth {
    if (isBossSet) return 2.2;
    switch (rarity) {
      case ItemRarity.legendary:
        return 2.0;
      case ItemRarity.epic:
        return 1.6;
      case ItemRarity.rare:
        return 1.3;
      case ItemRarity.common:
        return 1.0;
    }
  }

  int getAffixValue(AffixType type) {
    int total = 0;
    for (var a in affixes) {
      if (a.type == type) total += a.value;
    }
    return total;
  }

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
        name: json['name'],
        rarity: ItemRarity.values[json['rarity']],
        slot: GearSlot.values[json['slot']],
        baseStat: json['baseStat'],
        upgradeLevel: json['upgradeLevel'] ?? 0,
        affixes: (json['affixes'] as List? ?? [])
            .map((a) => GearAffix.fromJson(a))
            .toList(),
        setGroup: json['setGroup'] ?? 'none',
        isSoulbound: json['isSoulbound'] ?? false,
        icon: json['icon'] ?? '🗡️',
      );
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

final List<ShinobiLocation> shinobiLocations = [
  const ShinobiLocation(
    id: 'loc_gate',
    name: 'Brama Konohagakure',
    minLevel: 1,
    description: 'Obrzeża wioski Liścia. Dzikie psy i zbiegli bandyci.',
    icon: '⛩️',
  ),
  const ShinobiLocation(
    id: 'loc_forest',
    name: 'Las Śmierci (Strefa 44)',
    minLevel: 10,
    description: 'Poligon egzaminacyjny. Trujące bagna i szpiedzy.',
    icon: '🌲',
  ),
  const ShinobiLocation(
    id: 'loc_waves',
    name: 'Kraj Fali (Most Tenkū)',
    minLevel: 22,
    description: 'Mgliste wybrzeża, renegaci Kiri i zabójcy Zabuzy.',
    icon: '🌊',
  ),
  const ShinobiLocation(
    id: 'loc_valley',
    name: 'Dolina Końca',
    minLevel: 36,
    description: 'Historyczne posągi i niebezpieczne klony shinobi.',
    icon: '⚡',
  ),
  const ShinobiLocation(
    id: 'loc_akatsuki',
    name: 'Kryjówka Akatsuki',
    minLevel: 50,
    description: 'Podziemna baza organizacji w płaszczach z chmurami.',
    icon: '☁️',
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

  const EnemyTemplate({
    required this.id,
    required this.name,
    required this.title,
    required this.baseHp,
    required this.baseAtk,
    required this.locationId,
    this.isBoss = false,
    required this.icon,
    this.critRate = 5,
    this.dodgeRate = 5,
    this.armorPierce = 0,
    this.flatBlock = 0,
  });
}

// 4 Zwykłych Przeciwników na każdą z 5 stref (łącznie 20)
final List<EnemyTemplate> standardEnemiesPool = [
  // ⛩️ Brama (Lvl 1+)
  const EnemyTemplate(id: 'en_dog', name: 'Dziki Ninja-Pies', title: 'Agresywny Ogar', baseHp: 38, baseAtk: 9, locationId: 'loc_gate', icon: '🐕', dodgeRate: 8),
  const EnemyTemplate(id: 'en_bandit', name: 'Bandyta z Kraju Fal', title: 'Zbiegły Rzezimieszek', baseHp: 48, baseAtk: 11, locationId: 'loc_gate', icon: '🥷'),
  const EnemyTemplate(id: 'en_sound_spy', name: 'Szpieg Dźwięku', title: 'Infiltrator Otogakure', baseHp: 42, baseAtk: 12, locationId: 'loc_gate', icon: '👤', dodgeRate: 12),
  const EnemyTemplate(id: 'en_deserter', name: 'Wędrowny Dezerter', title: 'Zbiegły Genin', baseHp: 52, baseAtk: 10, locationId: 'loc_gate', icon: '🗡️', critRate: 8),

  // 🌲 Las Śmierci (Lvl 10+)
  const EnemyTemplate(id: 'en_rain', name: 'Ninja Deszczu', title: 'Zabójca Amegakure', baseHp: 80, baseAtk: 15, locationId: 'loc_forest', icon: '🌧️', critRate: 10),
  const EnemyTemplate(id: 'en_rock_spy', name: 'Szpieg Skały', title: 'Infiltrator Iwagakure', baseHp: 95, baseAtk: 14, locationId: 'loc_forest', icon: '🗿', flatBlock: 4),
  const EnemyTemplate(id: 'en_centipede', name: 'Gigantyczna Krocionoga', title: 'Paskuda Lasu Śmierci', baseHp: 115, baseAtk: 13, locationId: 'loc_forest', icon: '🐛', flatBlock: 6),
  const EnemyTemplate(id: 'en_zaku', name: 'Zaku Abumi', title: 'Genin Ukrytego Dźwięku', baseHp: 88, baseAtk: 17, locationId: 'loc_forest', icon: '💨', armorPierce: 12),

  // 🌊 Kraj Fali (Lvl 22+)
  const EnemyTemplate(id: 'en_mist_assassin', name: 'Zabójca z Mgły', title: 'Łowca Kiri', baseHp: 135, baseAtk: 22, locationId: 'loc_waves', icon: '🌫️', dodgeRate: 14),
  const EnemyTemplate(id: 'en_haku', name: 'Haku', title: 'Władca Lodowych Luster', baseHp: 128, baseAtk: 24, locationId: 'loc_waves', icon: '❄️', dodgeRate: 18, critRate: 14),
  const EnemyTemplate(id: 'en_gato_bandit', name: 'Bandyta Gatō', title: 'Ciężki Rębacz', baseHp: 165, baseAtk: 21, locationId: 'loc_waves', icon: '🪓', flatBlock: 8),
  const EnemyTemplate(id: 'en_kaido', name: 'Najemnik Zabuzy (Kaidō)', title: 'Szermierz Śmierci', baseHp: 142, baseAtk: 25, locationId: 'loc_waves', icon: '⚔️', critRate: 12),

  // ⚡ Dolina Końca (Lvl 36+)
  const EnemyTemplate(id: 'en_zetsu', name: 'Klon Białego Zetsu', title: 'Syntetyczny Shinobi', baseHp: 190, baseAtk: 26, locationId: 'loc_valley', icon: '🪴', dodgeRate: 12),
  const EnemyTemplate(id: 'en_kimimaro_base', name: 'Kimimaro (Wstępna Forma)', title: 'Klan Kaguya', baseHp: 225, baseAtk: 28, locationId: 'loc_valley', icon: '🦴', flatBlock: 12, armorPierce: 10),
  const EnemyTemplate(id: 'en_sasuke_curse', name: 'Klon Cienia Sasuke', title: 'Przeklęta Pieczęć', baseHp: 180, baseAtk: 32, locationId: 'loc_valley', icon: '⚡', critRate: 18, dodgeRate: 15),
  const EnemyTemplate(id: 'en_curse_scout', name: 'Opętany Zwiadowca Klątwy', title: 'Strażnik Pieczęci', baseHp: 205, baseAtk: 30, locationId: 'loc_valley', icon: '👹', critRate: 15),

  // ☁️ Kryjówka Akatsuki (Lvl 50+)
  const EnemyTemplate(id: 'en_akatsuki_agent', name: 'Agent Akatsuki', title: 'Najemnik Cienia', baseHp: 255, baseAtk: 34, locationId: 'loc_akatsuki', icon: '⛩️', armorPierce: 15, critRate: 15),
  const EnemyTemplate(id: 'en_kisame_scout', name: 'Kisame (Zwiadowca)', title: 'Potwór Ukrytej Mgły', baseHp: 320, baseAtk: 33, locationId: 'loc_akatsuki', icon: '🦈', flatBlock: 10),
  const EnemyTemplate(id: 'en_hiruko', name: 'Kukła Bojowa Sasoriego', title: 'Hiruko', baseHp: 280, baseAtk: 35, locationId: 'loc_akatsuki', icon: '🦂', armorPierce: 20, flatBlock: 12),
  const EnemyTemplate(id: 'en_deidara_clone', name: 'Eksplodujący Klon Deidary', title: 'Żywa Bomba Gliniasta', baseHp: 230, baseAtk: 40, locationId: 'loc_akatsuki', icon: '💣', critRate: 20, armorPierce: 25),
];

// Po 1 Bossie na każdą strefę
final List<EnemyTemplate> bossesPool = [
  const EnemyTemplate(id: 'boss_mizuki', name: 'Mizuki', title: 'Zdrajca Liścia', baseHp: 95, baseAtk: 15, locationId: 'loc_gate', isBoss: true, icon: '📜', critRate: 8, dodgeRate: 6, armorPierce: 5),
  const EnemyTemplate(id: 'boss_dosu', name: 'Dosu Kinuta', title: 'Genin Ukrytego Dźwięku', baseHp: 135, baseAtk: 19, locationId: 'loc_forest', isBoss: true, icon: '🦻', critRate: 14, dodgeRate: 10, armorPierce: 8),
  const EnemyTemplate(id: 'boss_zabuza', name: 'Zabuza Momochi', title: 'Demon Ukrytej Mgły', baseHp: 185, baseAtk: 26, locationId: 'loc_waves', isBoss: true, icon: '🗡️', critRate: 15, dodgeRate: 12, armorPierce: 15),
  const EnemyTemplate(id: 'boss_gaara', name: 'Gaara Pustyni', title: 'Głos Shukaku', baseHp: 255, baseAtk: 30, locationId: 'loc_valley', isBoss: true, icon: '🏺', flatBlock: 12, armorPierce: 14),
  const EnemyTemplate(id: 'boss_itachi', name: 'Itachi Uchiha', title: 'Mistrz Sharingana', baseHp: 350, baseAtk: 38, locationId: 'loc_akatsuki', isBoss: true, icon: '👁️', critRate: 20, dodgeRate: 20, armorPierce: 25),
];

class DungeonBossTemplate {
  final String id;
  final String name;
  final String title;
  final int baseHp;
  final int baseAtk;
  final int minLevel;
  final String setGroup;
  final String icon;

  const DungeonBossTemplate({
    required this.id,
    required this.name,
    required this.title,
    required this.baseHp,
    required this.baseAtk,
    required this.minLevel,
    required this.setGroup,
    required this.icon,
  });
}

final List<DungeonBossTemplate> dungeonBossesPool = [
  const DungeonBossTemplate(id: 'dung_kyubi', name: 'Demon Kurama', title: 'Gniew Kyūbi (6 Ogonów)', baseHp: 320, baseAtk: 32, minLevel: 15, setGroup: 'boss_kyubi', icon: '🦊'),
  const DungeonBossTemplate(id: 'dung_susanoo', name: 'Perfekcyjne Susanoo', title: 'Boski Awatar Madary', baseHp: 540, baseAtk: 48, minLevel: 35, setGroup: 'boss_susanoo', icon: '🛡️'),
  const DungeonBossTemplate(id: 'dung_kaguya', name: 'Kaguya Ōtsutsuki', title: 'Matka Czakry i Wymiarów', baseHp: 850, baseAtk: 65, minLevel: 55, setGroup: 'boss_kaguya', icon: '🌕'),
];

class BossSetGearPiece {
  final String setGroup;
  final String baseName;
  final GearSlot slot;
  final int baseStat;
  final String icon;

  const BossSetGearPiece({
    required this.setGroup,
    required this.baseName,
    required this.slot,
    required this.baseStat,
    required this.icon,
  });
}

final List<BossSetGearPiece> bossExclusiveSetsPool = [
  const BossSetGearPiece(setGroup: 'boss_kyubi', baseName: 'Pazur Dziewięcioogoniastego', slot: GearSlot.weapon, baseStat: 26, icon: '🔥'),
  const BossSetGearPiece(setGroup: 'boss_kyubi', baseName: 'Płaszcz Czakry Lisa', slot: GearSlot.armor, baseStat: 22, icon: '🦊'),
  const BossSetGearPiece(setGroup: 'boss_kyubi', baseName: 'Korona Płomiennego Lisa', slot: GearSlot.helmet, baseStat: 18, icon: '👑'),
  const BossSetGearPiece(setGroup: 'boss_kyubi', baseName: 'Ślad Demona Zniszczenia', slot: GearSlot.boots, baseStat: 18, icon: '🐾'),
  const BossSetGearPiece(setGroup: 'boss_kyubi', baseName: 'Pieczęć Ośmiu Trygramów', slot: GearSlot.trinket, baseStat: 22, icon: '🌀'),

  const BossSetGearPiece(setGroup: 'boss_susanoo', baseName: 'Klinga Totsuka', slot: GearSlot.weapon, baseStat: 36, icon: '🗡️'),
  const BossSetGearPiece(setGroup: 'boss_susanoo', baseName: 'Żebra Boskiego Susanoo', slot: GearSlot.armor, baseStat: 34, icon: '🛡️'),
  const BossSetGearPiece(setGroup: 'boss_susanoo', baseName: 'Hełm Wojownika Tengu', slot: GearSlot.helmet, baseStat: 26, icon: '👺'),
  const BossSetGearPiece(setGroup: 'boss_susanoo', baseName: 'Kroki Wiecznego Cienia', slot: GearSlot.boots, baseStat: 26, icon: '👣'),
  const BossSetGearPiece(setGroup: 'boss_susanoo', baseName: 'Zwierciadło Yata', slot: GearSlot.trinket, baseStat: 30, icon: '🪞'),

  const BossSetGearPiece(setGroup: 'boss_kaguya', baseName: 'Kość Popiołu Wszechunicestwienia', slot: GearSlot.weapon, baseStat: 48, icon: '🦴'),
  const BossSetGearPiece(setGroup: 'boss_kaguya', baseName: 'Szata Boskiego Drzewa', slot: GearSlot.armor, baseStat: 44, icon: '👘'),
  const BossSetGearPiece(setGroup: 'boss_kaguya', baseName: 'Diadem Rinne-Sharingana', slot: GearSlot.helmet, baseStat: 36, icon: '👁️'),
  const BossSetGearPiece(setGroup: 'boss_kaguya', baseName: 'Lewitacja Międzywymiarowa', slot: GearSlot.boots, baseStat: 36, icon: '✨'),
  const BossSetGearPiece(setGroup: 'boss_kaguya', baseName: 'Kropla Pierwotnej Czakry', slot: GearSlot.trinket, baseStat: 40, icon: '🌌'),
];

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

final List<GearArchetype> standardArchetypesPool = [
  const GearArchetype(baseName: 'Stalowy Kunai Bojowy', slot: GearSlot.weapon, baseStat: 7, icon: '🗡️'),
  const GearArchetype(baseName: 'Tanto ANBU Cienia', slot: GearSlot.weapon, baseStat: 10, setGroup: 'anbu', icon: '⚔️'),
  const GearArchetype(baseName: 'Ostrze Wiatru Myōboku', slot: GearSlot.weapon, baseStat: 14, setGroup: 'myoboku', icon: '🍃'),

  const GearArchetype(baseName: 'Kamizelka Taktyczna Chunina', slot: GearSlot.armor, baseStat: 6, icon: '🦺'),
  const GearArchetype(baseName: 'Zbroja Skrytobójcy ANBU', slot: GearSlot.armor, baseStat: 9, setGroup: 'anbu', icon: '🥋'),
  const GearArchetype(baseName: 'Szata Mędrca Ropuszego', slot: GearSlot.armor, baseStat: 13, setGroup: 'myoboku', icon: '👘'),

  const GearArchetype(baseName: 'Wzmocniony Ochraniacz Liścia', slot: GearSlot.helmet, baseStat: 4, icon: '🛡️'),
  const GearArchetype(baseName: 'Porcelanowa Maska Lisa ANBU', slot: GearSlot.helmet, baseStat: 7, setGroup: 'anbu', icon: '🎭'),
  const GearArchetype(baseName: 'Opaska Mistrza Trybu Mędrca', slot: GearSlot.helmet, baseStat: 10, setGroup: 'myoboku', icon: '🐸'),

  const GearArchetype(baseName: 'Wzmocnione Sandały Shinobi', slot: GearSlot.boots, baseStat: 4, icon: '🥾'),
  const GearArchetype(baseName: 'Ciche Trzewiki Tropiciela ANBU', slot: GearSlot.boots, baseStat: 7, setGroup: 'anbu', icon: '👣'),
  const GearArchetype(baseName: 'Kamasze Żabiej Zwinności', slot: GearSlot.boots, baseStat: 10, setGroup: 'myoboku', icon: '👟'),

  const GearArchetype(baseName: 'Amulet Ochronny Liścia', slot: GearSlot.trinket, baseStat: 5, icon: '📿'),
  const GearArchetype(baseName: 'Pieczęć Operacyjna ANBU', slot: GearSlot.trinket, baseStat: 8, setGroup: 'anbu', icon: '💠'),
  const GearArchetype(baseName: 'Wisiorek Kamienia Myōboku', slot: GearSlot.trinket, baseStat: 12, setGroup: 'myoboku', icon: '🔮'),
];

class Jutsu {
  final String id;
  final String name;
  final int chakraCost;
  final double powerMultiplier;
  final String effectDescription;
  final int costRyo;
  final Color color;

  const Jutsu({
    required this.id,
    required this.name,
    required this.chakraCost,
    required this.powerMultiplier,
    required this.effectDescription,
    required this.costRyo,
    required this.color,
  });
}

final List<Jutsu> allJutsuPool = [
  const Jutsu(
    id: 'j_taijutsu',
    name: 'Seria Ciosów Taijutsu',
    chakraCost: 0,
    powerMultiplier: 1.0,
    effectDescription: 'Podstawowe ataki wręcz. Nie zużywa czakry.',
    costRyo: 0,
    color: Color(0xFFB0BEC5),
  ),
  const Jutsu(
    id: 'j_fireball',
    name: 'Katon: Kula Ognia',
    chakraCost: 20,
    powerMultiplier: 1.6,
    effectDescription: 'Klasyczna technika Uchiha o wysokiej sile ognia.',
    costRyo: 80,
    color: Color(0xFFFF7043),
  ),
  const Jutsu(
    id: 'j_water_dragon',
    name: 'Suiton: Smoczy Wodospad',
    chakraCost: 25,
    powerMultiplier: 1.8,
    effectDescription: 'Masywny wodny wir kruszący obronę przeciwnika.',
    costRyo: 150,
    color: Color(0xFF42A5F5),
  ),
  const Jutsu(
    id: 'j_chidori',
    name: 'Raiton: Chidori (Tysiąc Ptaków)',
    chakraCost: 35,
    powerMultiplier: 2.3,
    effectDescription: 'Skupione cięcie błyskawicy penetrujące pancerz.',
    costRyo: 280,
    color: Color(0xFFFFEE58),
  ),
  const Jutsu(
    id: 'j_rasengan',
    name: 'Rasengan (Wirująca Sfera)',
    chakraCost: 40,
    powerMultiplier: 2.6,
    effectDescription: 'Skondensowana czakra bez pieczęci o dewastującej mocy.',
    costRyo: 400,
    color: Color(0xFF26C6DA),
  ),
  const Jutsu(
    id: 'j_kirin',
    name: 'Raiton: Kirin (Bestia Błyskawic)',
    chakraCost: 65,
    powerMultiplier: 3.5,
    effectDescription: 'Prawdziwy piorun ściągnięty z niebios. Niszczycielska siła.',
    costRyo: 750,
    color: Color(0xFFE040FB),
  ),
];

enum ConsumableType {
  healHpPercent,
  healCpPercent,
  ramenRestore,
  buffAtk,
  smokeEscape,
  directDmg,
}

class Consumable {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int price;
  final ConsumableType type;
  final int value;

  const Consumable({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.price,
    required this.type,
    required this.value,
  });

  String get statBonusText {
    switch (type) {
      case ConsumableType.healHpPercent:
        return 'Odnawia $value% Max HP';
      case ConsumableType.healCpPercent:
        return 'Odnawia $value% Max CP';
      case ConsumableType.ramenRestore:
        return 'Odnawia 100% HP/CP i daje +$value Max HP/CP';
      case ConsumableType.buffAtk:
        return 'Zwiększa bazowy atak o +$value na stałe';
      case ConsumableType.smokeEscape:
        return 'Natychmiastowa ucieczka z walki z mobem';
      case ConsumableType.directDmg:
        return 'Zadaje 35-150 bezpośrednich obrażeń w walce';
    }
  }
}

final List<Consumable> allConsumables = [
  const Consumable(
    id: 'c_pill',
    name: 'Pigułka Żywnościowa',
    description: 'Koncentrat witamin i czakry ninja.',
    icon: '💊',
    price: 35,
    type: ConsumableType.healHpPercent,
    value: 35,
  ),
  const Consumable(
    id: 'c_dango',
    name: 'Słodkie Dango Czakry',
    description: 'Przysmak przywracający zapasy energii.',
    icon: '🍡',
    price: 30,
    type: ConsumableType.healCpPercent,
    value: 40,
  ),
  const Consumable(
    id: 'c_bandage',
    name: 'Opatrunek Polowy Medyka',
    description: 'Skuteczne bandaże polowe tamujące krwawienie.',
    icon: '🩹',
    price: 55,
    type: ConsumableType.healHpPercent,
    value: 60,
  ),
  const Consumable(
    id: 'c_ramen',
    name: 'Specjalny Ramen Ichiraku',
    description: 'Ulubione danie Hokage. Wzmacnia organizm.',
    icon: '🍜',
    price: 180,
    type: ConsumableType.ramenRestore,
    value: 12,
  ),
  const Consumable(
    id: 'c_ointment',
    name: 'Maść Klanu Hyūga',
    description: 'Tradycyjna maść wzmacniająca mięśnie i cios.',
    icon: '🧪',
    price: 240,
    type: ConsumableType.buffAtk,
    value: 3,
  ),
  const Consumable(
    id: 'c_smoke',
    name: 'Bomba Dymna',
    description: 'Pozwala błyskawicznie uciec przed zwykłym wrogiem.',
    icon: '💨',
    price: 45,
    type: ConsumableType.smokeEscape,
    value: 0,
  ),
  const Consumable(
    id: 'c_kibaku',
    name: 'Pieczęć Wybuchowa (Kibaku Fūda)',
    description: 'Zadaje potężne obrażenia w walce.',
    icon: '💥',
    price: 50,
    type: ConsumableType.directDmg,
    value: 60,
  ),
];

const String matIronOre = 'mat_iron_ore';
const String matSteel = 'mat_steel';
const String matCrystal = 'mat_crystal';
const String matDungeonKey = 'mat_dungeon_key';

class CraftingMaterialInfo {
  final String id;
  final String name;
  final String icon;

  const CraftingMaterialInfo({required this.id, required this.name, required this.icon});
}

final Map<String, CraftingMaterialInfo> craftingMaterials = {
  matIronOre: const CraftingMaterialInfo(id: matIronOre, name: 'Ruda Żelaza Shinobi', icon: '🪨'),
  matSteel: const CraftingMaterialInfo(id: matSteel, name: 'Wzbogacona Stal Liścia', icon: '🧱'),
  matCrystal: const CraftingMaterialInfo(id: matCrystal, name: 'Kryształ Czakry Żywiołów', icon: '💎'),
  matDungeonKey: const CraftingMaterialInfo(id: matDungeonKey, name: 'Klucz do Lochów', icon: '🗝️'),
};

class ExamInfo {
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

  const ExamInfo({
    required this.targetRankIndex,
    required this.rankTitle,
    required this.requiredLevel,
    required this.examinerName,
    required this.examinerTitle,
    required this.hp,
    required this.atk,
    this.critRate = 8,
    this.dodgeRate = 8,
    required this.icon,
  });
}

final List<ExamInfo> shinobiExams = [
  const ExamInfo(
    targetRankIndex: 1,
    rankTitle: 'Genin',
    requiredLevel: 4,
    examinerName: 'Iruka Umino',
    examinerTitle: 'Wychowawca Akademii',
    hp: 90,
    atk: 14,
    icon: '📚',
  ),
  const ExamInfo(
    targetRankIndex: 2,
    rankTitle: 'Chūnin',
    requiredLevel: 12,
    examinerName: 'Ibiki Morino',
    examinerTitle: 'Dowódca Oddziału Przesłuchań',
    hp: 160,
    atk: 22,
    critRate: 12,
    dodgeRate: 10,
    icon: '🧠',
  ),
  const ExamInfo(
    targetRankIndex: 3,
    rankTitle: 'Tokubetsu Jōnin',
    requiredLevel: 22,
    examinerName: 'Anko Mitarashi',
    examinerTitle: 'Egzaminatorka Lasu Śmierci',
    hp: 240,
    atk: 29,
    critRate: 14,
    dodgeRate: 12,
    icon: '🐍',
  ),
  const ExamInfo(
    targetRankIndex: 4,
    rankTitle: 'Jōnin Bojowy',
    requiredLevel: 35,
    examinerName: 'Kakashi Hatake',
    examinerTitle: 'Kopiujący Ninja',
    hp: 350,
    atk: 38,
    critRate: 16,
    dodgeRate: 16,
    icon: '⚡',
  ),
  const ExamInfo(
    targetRankIndex: 5,
    rankTitle: 'Elita ANBU (Korzeń)',
    requiredLevel: 48,
    examinerName: 'Danzō Shimura',
    examinerTitle: 'Władca Ciemności Konohy',
    hp: 460,
    atk: 47,
    critRate: 18,
    dodgeRate: 18,
    icon: '👁️',
  ),
  const ExamInfo(
    targetRankIndex: 6,
    rankTitle: 'Legendarny Sannin / Kage',
    requiredLevel: 60,
    examinerName: 'Jiraiya (Żabi Mędrzec)',
    examinerTitle: 'Mistrz Sannin',
    hp: 600,
    atk: 56,
    critRate: 20,
    dodgeRate: 20,
    icon: '🐸',
  ),
];

class VillageMission {
  final String id;
  final String rank;
  final int minRankIndex;
  final String title;
  final String desc;
  final String locationId;
  final MissionType type;
  final String? targetEnemyId;
  final String? supplyItemId;
  final int requiredCount;
  final int rewardRyo;
  final int rewardExp;

  const VillageMission({
    required this.id,
    required this.rank,
    required this.minRankIndex,
    required this.title,
    required this.desc,
    required this.locationId,
    required this.type,
    this.targetEnemyId,
    this.supplyItemId,
    required this.requiredCount,
    required this.rewardRyo,
    required this.rewardExp,
  });
}

final List<VillageMission> allMissionsPool = [
  const VillageMission(
    id: 'm_gate_patrol',
    rank: 'D',
    minRankIndex: 0,
    title: 'Patrol Przedpola Bramy',
    desc: 'Wyeliminuj zagrażające kupcom dzikie psy (x3).',
    locationId: 'loc_gate',
    type: MissionType.killCount,
    targetEnemyId: 'en_dog',
    requiredCount: 3,
    rewardRyo: 70,
    rewardExp: 50,
  ),
  const VillageMission(
    id: 'm_gate_iron',
    rank: 'D',
    minRankIndex: 0,
    title: 'Dostawa Rudy dla Kuźni',
    desc: 'Dostarcz rudę żelaza wydobytą na patrolu (x2).',
    locationId: 'loc_gate',
    type: MissionType.itemSupply,
    supplyItemId: matIronOre,
    requiredCount: 2,
    rewardRyo: 85,
    rewardExp: 60,
  ),
  const VillageMission(
    id: 'm_mizuki_hunt',
    rank: 'C',
    minRankIndex: 1,
    title: 'Schwytanie Zdrajcy Mizukiego',
    desc: 'Pokonaj Mizukiego, który czai się pod Bramą Konohy.',
    locationId: 'loc_gate',
    type: MissionType.bossHunt,
    targetEnemyId: 'boss_mizuki',
    requiredCount: 1,
    rewardRyo: 150,
    rewardExp: 140,
  ),
  const VillageMission(
    id: 'm_forest_rain',
    rank: 'C',
    minRankIndex: 1,
    title: 'Zasadzka w Lesie Śmierci',
    desc: 'Zneutralizuj wrogich ninja Deszczu (x4).',
    locationId: 'loc_forest',
    type: MissionType.killCount,
    targetEnemyId: 'en_rain',
    requiredCount: 4,
    rewardRyo: 160,
    rewardExp: 130,
  ),
  const VillageMission(
    id: 'm_dosu_hunt',
    rank: 'C',
    minRankIndex: 1,
    title: 'Uciszenie Dźwięku w Lesie',
    desc: 'Pokonaj Dosu Kinutę ukrywającego się w koronach drzew Lasu Śmierci.',
    locationId: 'loc_forest',
    type: MissionType.bossHunt,
    targetEnemyId: 'boss_dosu',
    requiredCount: 1,
    rewardRyo: 220,
    rewardExp: 200,
  ),
  const VillageMission(
    id: 'm_waves_zabuza',
    rank: 'B',
    minRankIndex: 2,
    title: 'Pojedynek na Zamglonym Moście',
    desc: 'Odszukaj i pokonaj Demona Ukrytej Mgły, Zabuzę Momochi.',
    locationId: 'loc_waves',
    type: MissionType.bossHunt,
    targetEnemyId: 'boss_zabuza',
    requiredCount: 1,
    rewardRyo: 320,
    rewardExp: 300,
  ),
  const VillageMission(
    id: 'm_valley_gaara',
    rank: 'A',
    minRankIndex: 3,
    title: 'Spacyfikowanie Głosów Pustyni',
    desc: 'Powstrzymaj szalejącego Gaarę w Dolinie Końca.',
    locationId: 'loc_valley',
    type: MissionType.bossHunt,
    targetEnemyId: 'boss_gaara',
    requiredCount: 1,
    rewardRyo: 500,
    rewardExp: 450,
  ),
  const VillageMission(
    id: 'm_akatsuki_itachi',
    rank: 'S',
    minRankIndex: 4,
    title: 'Infiltracja Czerwonego Księżyca',
    desc: 'Staw czoła samemu Itachiemu Uchiha w kryjówce Akatsuki.',
    locationId: 'loc_akatsuki',
    type: MissionType.bossHunt,
    targetEnemyId: 'boss_itachi',
    requiredCount: 1,
    rewardRyo: 900,
    rewardExp: 800,
  ),
];
