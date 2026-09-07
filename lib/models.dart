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

class GearAffix {
  final AffixType type;
  final int value;

  const GearAffix({required this.type, required this.value});

  String get label {
    switch (type) {
      case AffixType.critRate: return 'Szansa na krytyk: +$value%';
      case AffixType.dodgeRate: return 'Unik (Kawarimi): +$value%';
      case AffixType.armorPierce: return 'Przebicie pancerza: +$value%';
      case AffixType.lifeSteal: return 'Kradzież życia: +$value%';
      case AffixType.hpRegen: return 'Regeneracja HP: +$value';
      case AffixType.chakraRegen: return 'Regeneracja CP: +$value';
      case AffixType.bonusHp: return 'Bonusowe HP: +$value';
      case AffixType.bonusChakra: return 'Bonusowa Czakra: +$value';
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
    this.icon = '📦',
  });

  int get effectiveStat => baseStat + (upgradeLevel * 3);

  int get sellPrice => ((baseStat * 8) + (upgradeLevel * 15) + (rarity.index * 25)).round();

  int get merchantSellPrice => (sellPrice * 1.4).round();

  int get marketValue => sellPrice * 2;

  int get sealingCost => 50 + (rarity.index * 75) + (upgradeLevel * 20);

  bool get isBossSet => setGroup != 'none' && (setGroup.startsWith('boss_') || setGroup == 'anbu' || setGroup == 'myoboku');

  Color get color {
    switch (rarity) {
      case ItemRarity.common: return Colors.white70;
      case ItemRarity.rare: return const Color(0xFF448AFF);
      case ItemRarity.epic: return const Color(0xFFBA68C8);
      case ItemRarity.legendary: return const Color(0xFFFFD54F);
    }
  }

  Color get borderColor {
    if (isBossSet) return const Color(0xFFFF5252);
    return color;
  }

  double get borderWidth => rarity == ItemRarity.legendary || isBossSet ? 2.0 : 1.2;

  String get rarityLabel {
    switch (rarity) {
      case ItemRarity.common: return 'Zwykły';
      case ItemRarity.rare: return 'Rzadki';
      case ItemRarity.epic: return 'Epicki';
      case ItemRarity.legendary: return 'Legendarny';
    }
  }

  String get displayName => upgradeLevel > 0 ? '$name +$upgradeLevel' : name;

  int getAffixValue(AffixType type) {
    int total = 0;
    for (var a in affixes) {
      if (a.type == type) total += a.value;
    }
    return total;
  }

  NinjaGear copyWith({
    int? upgradeLevel,
    bool? isSoulbound,
    bool? isFavorite,
  }) {
    return NinjaGear(
      name: name,
      rarity: rarity,
      slot: slot,
      baseStat: baseStat,
      upgradeLevel: upgradeLevel ?? this.upgradeLevel,
      affixes: affixes,
      setGroup: setGroup,
      isSoulbound: isSoulbound ?? this.isSoulbound,
      isFavorite: isFavorite ?? this.isFavorite,
      icon: icon,
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
      affixes: (json['affixes'] as List?)?.map((a) => GearAffix.fromJson(a)).toList() ?? [],
      setGroup: json['setGroup'] as String? ?? 'none',
      isSoulbound: json['isSoulbound'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      icon: json['icon'] as String? ?? '📦',
    );
  }
}

// Pozostałe klasy stałe w models.dart (zachowane bez zmian)
enum ConsumableType { healHpPercent, healCpPercent, ramenRestore, buffAtk, smokeEscape, directDmg }

class Consumable {
  final String id;
  final String name;
  final ConsumableType type;
  final int value;
  final int price;
  final String icon;
  final String description;
  final String statBonusText;

  const Consumable({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.price,
    required this.icon,
    required this.description,
    required this.statBonusText,
  });
}

const List<Consumable> allConsumables = [
  Consumable(id: 'c_pill', name: 'Pigułka Żołnierska', type: ConsumableType.healHpPercent, value: 50, price: 30, icon: '💊', description: 'Odnawia 50% HP.', statBonusText: '+50% HP'),
  Consumable(id: 'c_dango', name: 'Trzy Kolory Dango', type: ConsumableType.healCpPercent, value: 60, price: 40, icon: '🍡', description: 'Odnawia 60% Czakry.', statBonusText: '+60% CP'),
  Consumable(id: 'c_bandage', name: 'Medyczne Bandaże', type: ConsumableType.healHpPercent, value: 30, price: 20, icon: '🩹', description: 'Odnawia 30% HP.', statBonusText: '+30% HP'),
  Consumable(id: 'c_ramen', name: 'Miska Ichiraku Ramen', type: ConsumableType.ramenRestore, value: 25, price: 150, icon: '🍜', description: 'Zwiększa maksymalne limity HP i CP na stałe.', statBonusText: '+25 Max HP/CP'),
  Consumable(id: 'c_kibaku', name: 'Pieczęć Wybuchowa', type: ConsumableType.directDmg, value: 1, price: 55, icon: '💥', description: 'Zadaje potężne obrażenia wrogowi w walce.', statBonusText: 'Wybuch w walce'),
  Consumable(id: 'c_smoke', name: 'Bomba Dymna', type: ConsumableType.smokeEscape, value: 1, price: 45, icon: '💨', description: 'Pozwala uciec ze zwykłej walki.', statBonusText: 'Ucieczka z walki'),
];

enum JutsuType { damage, healing, shield, stun }

class Jutsu {
  final String id;
  final String name;
  final JutsuType type;
  final int chakraCost;
  final double powerMultiplier;
  final int effectValue;
  final int minRankIndex;
  final int costRyo;
  final bool availableInVillage;
  final Color color;
  final String effectDescription;

  const Jutsu({
    required this.id,
    required this.name,
    required this.type,
    required this.chakraCost,
    required this.powerMultiplier,
    this.effectValue = 0,
    required this.minRankIndex,
    required this.costRyo,
    required this.availableInVillage,
    required this.color,
    required this.effectDescription,
  });
}

const List<Jutsu> allJutsuPool = [
  Jutsu(id: 'j_taijutsu', name: 'Seria Ciosów Wręcz', type: JutsuType.damage, chakraCost: 10, powerMultiplier: 1.2, minRankIndex: 0, costRyo: 0, availableInVillage: true, color: Colors.orange, effectDescription: 'Podstawowa technika fizyczna.'),
  Jutsu(id: 'j_fireball', name: 'Katon: Wielka Kula Ognia', type: JutsuType.damage, chakraCost: 25, powerMultiplier: 2.1, minRankIndex: 1, costRyo: 200, availableInVillage: true, color: Colors.deepOrange, effectDescription: 'Potężny atak ognistym żywiołem.'),
  Jutsu(id: 'j_chidori', name: 'Chidori (Tysiąc Ptaszków)', type: JutsuType.damage, chakraCost: 40, powerMultiplier: 3.4, minRankIndex: 3, costRyo: 800, availableInVillage: true, color: Colors.blueAccent, effectDescription: 'Skoncentrowana błyskawica przeszywająca wroga.'),
  Jutsu(id: 'j_rasenshuriken', name: 'Fūton: Rasenshuriken', type: JutsuType.damage, chakraCost: 75, powerMultiplier: 5.5, minRankIndex: 5, costRyo: 2200, availableInVillage: true, color: Colors.cyan, effectDescription: 'Niszczycielski wir wiatru zadający masowe obrażenia.'),
  Jutsu(id: 'j_medical', name: 'Szpiczasty Skalpel Czakry', type: JutsuType.healing, chakraCost: 20, powerMultiplier: 1.0, effectValue: 35, minRankIndex: 1, costRyo: 250, availableInVillage: true, color: Colors.green, effectDescription: 'Leczy rany za pomocą czakry medycznej.'),
  Jutsu(id: 'j_byakugo', name: 'Technika Uzdrowienia Mitotic (Byakugō)', type: JutsuType.healing, chakraCost: 60, powerMultiplier: 1.5, effectValue: 80, minRankIndex: 5, costRyo: 2500, availableInVillage: true, color: Color(0xFF2E7D32), effectDescription: 'Regeneruje ogromną ilość zdrowia.',),
  Jutsu(id: 'j_doton_wall', name: 'Doton: Kamienny Mur', type: JutsuType.shield, chakraCost: 20, powerMultiplier: 0.0, effectValue: 25, minRankIndex: 2, costRyo: 400, availableInVillage: true, color: Colors.brown, effectDescription: 'Tworzy barierę obronną.'),
  Jutsu(id: 'j_shadow_bind', name: 'Technika Cienia (Kagemane)', type: JutsuType.stun, chakraCost: 30, powerMultiplier: 1.2, minRankIndex: 2, costRyo: 500, availableInVillage: true, color: Colors.indigo, effectDescription: 'Unieruchamia przeciwnika na 1 turę.'),
  Jutsu(id: 'j_amaterasu', name: 'Kinjutsu: Czarne Płomienie Amaterasu', type: JutsuType.damage, chakraCost: 90, powerMultiplier: 7.0, minRankIndex: 6, costRyo: 5000, availableInVillage: false, color: Colors.purple, effectDescription: 'Sekretny zwój Mędrca: Płomienie, które nie gasną.'),
  Jutsu(id: 'j_hiraishin', name: 'Latający Bóg Grzmotu (Hiraishin)', type: JutsuType.damage, chakraCost: 70, powerMultiplier: 6.0, minRankIndex: 6, costRyo: 4500, availableInVillage: false, color: Colors.amber, effectDescription: 'Sekretny zwój Mędrca: Atak z prędkością światła.'),
  Jutsu(id: 'j_reaper', name: 'Pieczęć Boga Śmierci (Shiki Fūjin)', type: JutsuType.damage, chakraCost: 110, powerMultiplier: 9.5, minRankIndex: 6, costRyo: 7000, availableInVillage: false, color: Colors.redAccent, effectDescription: 'Sekretny zwój Mędrca: Ostateczne jutsu pieczętujące.'),
];

class ShinobiLocation {
  final String id;
  final String name;
  final String description;
  final int minLevel;
  final String icon;

  const ShinobiLocation({required this.id, required this.name, required this.description, required this.minLevel, required this.icon});
}

const List<ShinobiLocation> shinobiLocations = [
  ShinobiLocation(id: 'loc_gate', name: 'Brama Główna Konohy', description: 'Bezpieczniejsze obrzeża lasu, idealne na początek drogi.', minLevel: 1, icon: '⛩️'),
  ShinobiLocation(id: 'loc_forest', name: 'Gęsty Las Śmierci', description: 'Niebezpieczna puszcza pełna dzikich shinobi i pułapek.', minLevel: 10, icon: '🌲'),
  ShinobiLocation(id: 'loc_waves', name: 'Mroczny Kraj Fali', description: 'Mgliste wybrzeże i porty przemytników.', minLevel: 22, icon: '🌊'),
  ShinobiLocation(id: 'loc_valley', name: 'Dolina Końca', description: 'Legendarne miejsce starożytnych bitew.', minLevel: 35, icon: '⚡'),
  ShinobiLocation(id: 'loc_akatsuki', name: 'Kwatera Główna Akatsuki', description: 'Siedziba najpotężniejszych zbiegów.', minLevel: 50, icon: '☁️'),
];

enum EnemyPrefix { weak, normal, strong }

enum BossTrait { ironSkin, bloodEnrage, chakraLeech, poisonMaster, chakraThorns, dodgeManiac }

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
    required this.icon,
    this.critRate = 5,
    this.dodgeRate = 5,
    this.armorPierce = 0,
    this.flatBlock = 0,
    this.traits = const [],
  });

  double get powerRating => baseHp + (baseAtk * 3.5);
}

const List<EnemyTemplate> standardEnemiesPool = [
  EnemyTemplate(id: 'e_genin_rogue', name: 'Zbiegły Genin', baseHp: 45, baseAtk: 12, locationId: 'loc_gate', icon: '👤'),
  EnemyTemplate(id: 'e_wild_dog', name: 'Dziki Pies Ninja', baseHp: 35, baseAtk: 15, locationId: 'loc_gate', icon: '🐕'),
  EnemyTemplate(id: 'e_sound_ninja', name: 'Szpieg z Otogakure', baseHp: 95, baseAtk: 24, locationId: 'loc_forest', icon: '👥'),
  EnemyTemplate(id: 'e_puppet_scout', name: 'Zwiadowca z Suna', baseHp: 110, baseAtk: 28, locationId: 'loc_forest', icon: '🤖'),
  EnemyTemplate(id: 'e_mercenary', name: 'Najemnik z Mgły', baseHp: 180, baseAtk: 42, locationId: 'loc_waves', icon: '🥷'),
  EnemyTemplate(id: 'e_rogue_chunin', name: 'Zdradziecki Chūnin', baseHp: 210, baseAtk: 48, locationId: 'loc_waves', icon: '👺'),
  EnemyTemplate(id: 'e_elite_guard', name: 'Elitarny Strażnik Skały', baseHp: 310, baseAtk: 65, locationId: 'loc_valley', icon: '🛡️'),
  EnemyTemplate(id: 'e_curse_marked', name: 'Wojownik z Klątwą', baseHp: 360, baseAtk: 74, locationId: 'loc_valley', icon: '🟣'),
  EnemyTemplate(id: 'e_akatsuki_agent', name: 'Agent w Ciénistym Płaszczu', baseHp: 520, baseAtk: 95, locationId: 'loc_akatsuki', icon: '☁️'),
  EnemyTemplate(id: 'e_sannin_shadow', name: 'Widmo Wygnanego Sannina', baseHp: 650, baseAtk: 115, locationId: 'loc_akatsuki', icon: '🐍'),
];

const List<EnemyTemplate> bossesPool = [
  EnemyTemplate(id: 'b_zabuza', name: 'Zabuza Momochi', title: 'Demon z Ukrytej Mgły', baseHp: 380, baseAtk: 44, locationId: 'loc_waves', isBoss: true, icon: '🗡️', traits: [BossTrait.bloodEnrage]),
  EnemyTemplate(id: 'b_orochimaru', name: 'Eksperyment Orochimaru', title: 'Upadły Sannin', baseHp: 950, baseAtk: 88, locationId: 'loc_valley', isBoss: true, icon: '🐍', traits: [BossTrait.poisonMaster, BossTrait.chakraLeech]),
  EnemyTemplate(id: 'b_pain', name: 'Awatar Pains (Deva Path)', title: 'Przywódca Akatsuki', baseHp: 1600, baseAtk: 135, locationId: 'loc_akatsuki', isBoss: true, icon: '👁️', traits: [BossTrait.ironSkin, BossTrait.chakraThorns]),
];

class DungeonBossTemplate {
  final String id;
  final String name;
  final String title;
  final int minLevel;
  final int baseHp;
  final int baseAtk;
  final String icon;
  final String setGroup;

  const DungeonBossTemplate({required this.id, required this.name, required this.title, required this.minLevel, required this.baseHp, required this.baseAtk, required this.icon, required this.setGroup});
}

const List<DungeonBossTemplate> dungeonBossesPool = [
  DungeonBossTemplate(id: 'db_kyubi', name: 'Opętany Kyūbi (Mini)', title: 'Bestia o Dziewięciu Ogonach', minLevel: 15, baseHp: 750, baseAtk: 70, icon: '🦊', setGroup: 'boss_kyubi'),
  DungeonBossTemplate(id: 'db_susanoo', name: 'Fantom Susanoo', title: 'Boski Wojownik Uchiha', minLevel: 30, baseHp: 1400, baseAtk: 110, icon: '🛡️', setGroup: 'boss_susanoo'),
  DungeonBossTemplate(id: 'db_kaguya', name: 'Awatar Kaguya', title: 'Matka Czakry', minLevel: 50, baseHp: 2400, baseAtk: 160, icon: '🌙', setGroup: 'boss_kaguya'),
];

class BossSetPiece {
  final String baseName;
  final GearSlot slot;
  final int baseStat;
  final String setGroup;
  final String icon;

  const BossSetPiece({required this.baseName, required this.slot, required this.baseStat, required this.setGroup, required this.icon});
}

const List<BossSetPiece> bossExclusiveSetsPool = [
  BossSetPiece(baseName: 'Płaszcz Kyūbi (Ogon)', slot: GearSlot.armor, baseStat: 50, setGroup: 'boss_kyubi', icon: '🥋'),
  BossSetPiece(baseName: 'Pazur Demonicznej Lisiej Bestii', slot: GearSlot.weapon, baseStat: 65, setGroup: 'boss_kyubi', icon: '🗡️'),
  BossSetPiece(baseName: 'Maska Płonącego Susanoo', slot: GearSlot.helmet, baseStat: 45, setGroup: 'boss_susanoo', icon: '👑'),
  BossSetPiece(baseName: 'Nagolenniki Niebiańskiego Wojownika', slot: GearSlot.boots, baseStat: 42, setGroup: 'boss_susanoo', icon: '🥾'),
  BossSetPiece(baseName: 'Orb Czakry Bogini Kaguya', slot: GearSlot.trinket, baseStat: 75, setGroup: 'boss_kaguya', icon: '📿'),
  BossSetPiece(baseName: 'Szata Wymiarowego Bóstwa', slot: GearSlot.armor, baseStat: 80, setGroup: 'boss_kaguya', icon: '🥋'),
];

class GearArchetype {
  final String baseName;
  final GearSlot slot;
  final int baseStat;
  final String setGroup;
  final String icon;

  const GearArchetype({required this.baseName, required this.slot, required this.baseStat, required this.setGroup, required this.icon});
}

const List<GearArchetype> standardArchetypesPool = [
  GearArchetype(baseName: 'Kunai Bojowy', slot: GearSlot.weapon, baseStat: 12, setGroup: 'none', icon: '🗡️'),
  GearArchetype(baseName: 'Katana ANBU', slot: GearSlot.weapon, baseStat: 24, setGroup: 'anbu', icon: '⚔️'),
  GearArchetype(baseName: 'Miecz Ropuchy z Myoboku', slot: GearSlot.weapon, baseStat: 38, setGroup: 'myoboku', icon: '🗡️'),
  GearArchetype(baseName: 'Kamizelka Taktyczna', slot: GearSlot.armor, baseStat: 15, setGroup: 'none', icon: '🥋'),
  GearArchetype(baseName: 'Pancerz Operacyjny ANBU', slot: GearSlot.armor, baseStat: 28, setGroup: 'anbu', icon: '🛡️'),
  GearArchetype(baseName: 'Zbroja Mędrca Myoboku', slot: GearSlot.armor, baseStat: 42, setGroup: 'myoboku', icon: '🥋'),
  GearArchetype(baseName: 'Opaska Konohy', slot: GearSlot.helmet, baseStat: 10, setGroup: 'none', icon: '🛡️'),
  GearArchetype(baseName: 'Maska Przeciwgazowa ANBU', slot: GearSlot.helmet, baseStat: 22, setGroup: 'anbu', icon: '👺'),
  GearArchetype(baseName: 'Sandały Polowe', slot: GearSlot.boots, baseStat: 8, setGroup: 'none', icon: '🥾'),
  GearArchetype(baseName: 'Buty Skrytobójcy', slot: GearSlot.boots, baseStat: 20, setGroup: 'anbu', icon: '🥾'),
  GearArchetype(baseName: 'Talizman Czakry', slot: GearSlot.trinket, baseStat: 18, setGroup: 'none', icon: '📿'),
  GearArchetype(baseName: 'Naszyjnik Hokage', slot: GearSlot.trinket, baseStat: 35, setGroup: 'myoboku', icon: '📿'),
];

class CraftingMaterialInfo {
  final String id;
  final String name;
  final String icon;

  const CraftingMaterialInfo({required this.id, required this.name, required this.icon});
}

const String matIronOre = 'mat_iron';
const String matSteel = 'mat_steel';
const String matCrystal = 'mat_crystal';
const String matDungeonKey = 'mat_key';

const Map<String, CraftingMaterialInfo> craftingMaterials = {
  matIronOre: CraftingMaterialInfo(id: matIronOre, name: 'Ruda Żelaza', icon: '🪨'),
  matSteel: CraftingMaterialInfo(id: matSteel, name: 'Wzmocniona Stal', icon: '🧱'),
  matCrystal: CraftingMaterialInfo(id: matCrystal, name: 'Kryształ Czakry', icon: '💎'),
  matDungeonKey: CraftingMaterialInfo(id: matDungeonKey, name: 'Klucz do Lochu', icon: '🗝️'),
};

class NinjaExam {
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

  const NinjaExam({required this.targetRankIndex, required this.rankTitle, required this.requiredLevel, required this.examinerName, required this.examinerTitle, required this.hp, required this.atk, this.critRate = 5, this.dodgeRate = 5, required this.icon});
}

const List<NinjaExam> shinobiExams = [
  NinjaExam(targetRankIndex: 1, rankTitle: 'Genin', requiredLevel: 4, examinerName: 'Iruka Umino', examinerTitle: 'Instruktor Akademii', hp: 140, atk: 14, icon: '🟢'),
  NinjaExam(targetRankIndex: 2, rankTitle: 'Chūnin', requiredLevel: 12, examinerName: 'Shikamaru Nara', examinerTitle: 'Strateg Taktyczny', hp: 320, atk: 28, critRate: 10, icon: '🔵'),
  NinjaExam(targetRankIndex: 3, rankTitle: 'Tokubetsu Jōnin', requiredLevel: 22, examinerName: 'Anko Mitarashi', examinerTitle: 'Specjalny Agent', hp: 580, atk: 45, critRate: 12, dodgeRate: 10, icon: '🟣'),
  NinjaExam(targetRankIndex: 4, rankTitle: 'Jōnin Bojowy', requiredLevel: 35, examinerName: 'Kakashi Hatake', examinerTitle: 'Kopiujący Ninja', hp: 920, atk: 72, critRate: 15, dodgeRate: 15, icon: '🔴'),
  NinjaExam(targetRankIndex: 5, rankTitle: 'Elita ANBU (Korzeń)', requiredLevel: 48, examinerName: 'Danzō Shimura', examinerTitle: 'Przywódca Korzenia', hp: 1450, atk: 105, critRate: 18, dodgeRate: 18, icon: '⚫'),
  NinjaExam(targetRankIndex: 6, rankTitle: 'Legendarny Sannin / Kage', requiredLevel: 60, examinerName: 'Naruto & Sasuke', examinerTitle: 'Bóstwa Shinobi', hp: 2200, atk: 145, critRate: 22, dodgeRate: 22, icon: '👑'),
];

enum MissionType { killCount, bossHunt, itemSupply }

class NinjaMission {
  final String id;
  final int minRankIndex;
  final String rank;
  final String title;
  final String desc;
  final String locationId;
  final MissionType type;
  final String? targetEnemyId;
  final String? supplyItemId;
  final int requiredCount;
  final int rewardRyo;
  final int rewardExp;

  const NinjaMission({required this.id, required this.minRankIndex, required this.rank, required this.title, required this.desc, required this.locationId, required this.type, this.targetEnemyId, this.supplyItemId, required this.requiredCount, required this.rewardRyo, required this.rewardExp});
}

const List<NinjaMission> allMissionsPool = [
  NinjaMission(id: 'm_gate_1', minRankIndex: 0, rank: 'D', title: 'Oczyszczenie Bramy', desc: 'Pokonaj 3 zbiegłych geninów w pobliżu bramy.', locationId: 'loc_gate', type: MissionType.killCount, targetEnemyId: 'e_genin_rogue', requiredCount: 3, rewardRyo: 120, rewardExp: 100),
  NinjaMission(id: 'm_gate_2', minRankIndex: 0, rank: 'D', title: 'Zbiór Rudy Żelaza', desc: 'Dostarcz 2 sztuki rudy żelaza dla kowala.', locationId: 'loc_gate', type: MissionType.itemSupply, supplyItemId: matIronOre, requiredCount: 2, rewardRyo: 180, rewardExp: 140),
  NinjaMission(id: 'm_forest_1', minRankIndex: 1, rank: 'C', title: 'Szpieg z Otogakure', desc: 'Wyeliminuj 4 szpiegów w Lesie Śmierci.', locationId: 'loc_forest', type: MissionType.killCount, targetEnemyId: 'e_sound_ninja', requiredCount: 4, rewardRyo: 350, rewardExp: 300),
  NinjaMission(id: 'm_waves_1', minRankIndex: 2, rank: 'B', title: 'Demon z Mgły', desc: 'Pokonaj Zabuzu Momochi w Kraju Fali.', locationId: 'loc_waves', type: MissionType.bossHunt, targetEnemyId: 'b_zabuza', requiredCount: 1, rewardRyo: 850, rewardExp: 750),
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

  BingoTarget({required this.id, required this.name, required this.title, required this.zoneId, required this.minDepth, required this.enemy, required this.exclusiveReward, required this.bountyRyo, required this.bountyExp, this.isDefeated = false});
}

class MilestoneTracker {
  int enemiesSlain;
  int physicalHitsDealt;
  int jutsuCasts;
  int damageTaken;
  int bountiesClaimed;

  MilestoneTracker({this.enemiesSlain = 0, this.physicalHitsDealt = 0, this.jutsuCasts = 0, this.damageTaken = 0, this.bountiesClaimed = 0});

  Map<String, dynamic> toJson() => {
    'enemiesSlain': enemiesSlain,
    'physicalHitsDealt': physicalHitsDealt,
    'jutsuCasts': jutsuCasts,
    'damageTaken': damageTaken,
    'bountiesClaimed': bountiesClaimed,
  };

  factory MilestoneTracker.fromJson(Map<String, dynamic> json) {
    return MilestoneTracker(
      enemiesSlain: json['enemiesSlain'] as int? ?? 0,
      physicalHitsDealt: json['physicalHitsDealt'] as int? ?? 0,
      jutsuCasts: json['jutsuCasts'] as int? ?? 0,
      damageTaken: json['damageTaken'] as int? ?? 0,
      bountiesClaimed: json['bountiesClaimed'] as int? ?? 0,
    );
  }
}
