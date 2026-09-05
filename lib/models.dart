import 'package:flutter/material.dart';

enum ItemRarity { common, rare, epic, legendary }
enum ConsumableType { healHpPercent, healCpPercent, buffAtk, ramenRestore, directDmg, smokeEscape }
enum GearSlot { weapon, armor, helmet, boots, trinket }
enum JutsuEffect { none, burn, freeze, stun, lifesteal, shock }
enum EnemyPrefix { weak, normal, strong }
enum AffixType { critRate, dodgeRate, armorPierce, lifeSteal, hpRegen, chakraRegen, bonusHp, bonusChakra }

const String matIronOre = 'mat_iron_ore';
const String matSteel = 'mat_steel';
const String matCrystal = 'mat_crystal';
const String matDungeonKey = 'mat_dungeon_key';

class GearAffix {
  final AffixType type;
  final int value;

  const GearAffix({required this.type, required this.value});

  Map<String, dynamic> toJson() => {'type': type.index, 'value': value};

  factory GearAffix.fromJson(Map<String, dynamic> json) => GearAffix(
    type: AffixType.values[json['type'] ?? 0],
    value: json['value'] ?? 0,
  );

  String get label {
    switch (type) {
      case AffixType.critRate: return '💥 Szansa na krytyk: +$value%';
      case AffixType.dodgeRate: return '🪵 Unik (Kawarimi): +$value%';
      case AffixType.armorPierce: return '🗡️ Przebicie pancerza: +$value%';
      case AffixType.lifeSteal: return '🩸 Kradzież życia: +$value%';
      case AffixType.hpRegen: return '💚 Regeneracja HP: +$value/turę';
      case AffixType.chakraRegen: return '🌀 Regeneracja CP: +$value/turę';
      case AffixType.bonusHp: return '❤️ Dodatkowe HP: +$value';
      case AffixType.bonusChakra: return '⚡ Dodatkowa Czakra: +$value';
    }
  }
}

class CraftingMaterialInfo {
  final String id;
  final String name;
  final String icon;
  final String desc;

  const CraftingMaterialInfo({required this.id, required this.name, required this.icon, required this.desc});
}

const Map<String, CraftingMaterialInfo> craftingMaterials = {
  matIronOre: CraftingMaterialInfo(id: matIronOre, name: 'Ruda Żelaza Czakry', icon: '🪨', desc: 'Ruda do kucia rynsztunku (+1 do +3).'),
  matSteel: CraftingMaterialInfo(id: matSteel, name: 'Sztaba Tamahagane', icon: '🧱', desc: 'Wzmocniona stal (+4 do +6).'),
  matCrystal: CraftingMaterialInfo(id: matCrystal, name: 'Kryształ Esencji Czakry', icon: '💎', desc: 'Mityczny minerał kowalski (+7 do +9).'),
  matDungeonKey: CraftingMaterialInfo(id: matDungeonKey, name: 'Klucz do Lochów', icon: '🗝️', desc: 'Przepustka do leża Bossa.'),
};

class ShinobiLocation {
  final String id;
  final String name;
  final int minLevel;
  final String description;
  final String icon;

  const ShinobiLocation({required this.id, required this.name, required this.minLevel, required this.description, required this.icon});
}

const List<ShinobiLocation> shinobiLocations = [
  ShinobiLocation(id: 'loc_gate', name: 'Brama Konohagakure', minLevel: 1, description: 'Bezpieczne obrzeża i lasy wokół Wioski Liścia.', icon: '⛩️'),
  ShinobiLocation(id: 'loc_forest', name: 'Las Śmierci (Strefa 44)', minLevel: 10, description: 'Poligon pełny niebezpiecznych bestii i dzikich shinobi.', icon: '🌲'),
  ShinobiLocation(id: 'loc_waves', name: 'Kraj Fali / Most Tenkū', minLevel: 22, description: 'Tereny walk z nuke-ninami z Mgły i najemnikami.', icon: '🌊'),
  ShinobiLocation(id: 'loc_valley', name: 'Dolina Końca', minLevel: 36, description: 'Miejsce o skrajnej koncentracji prastarej czakry.', icon: '⚡'),
  ShinobiLocation(id: 'loc_akatsuki', name: 'Kryjówka Akatsuki', minLevel: 50, description: 'Strefa z najgroźniejszymi celami nacji shinobi.', icon: '☁️'),
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

  const DungeonBossTemplate({
    required this.id,
    required this.name,
    required this.title,
    required this.minLevel,
    required this.baseHp,
    required this.baseAtk,
    required this.icon,
    required this.setGroup,
  });
}

const List<DungeonBossTemplate> dungeonBossesPool = [
  DungeonBossTemplate(id: 'db_nine_tails', name: 'Demon Kurama', title: 'Gniew Kyūbi (6 Ogonów)', minLevel: 15, baseHp: 320, baseAtk: 32, icon: '🦊', setGroup: 'boss_kyubi'),
  DungeonBossTemplate(id: 'db_susanoo_madara', name: 'Perfekcyjne Susanoo', title: 'Boski Awatar Madary', minLevel: 35, baseHp: 540, baseAtk: 48, icon: '🛡️', setGroup: 'boss_susanoo'),
  DungeonBossTemplate(id: 'db_kaguya_god', name: 'Kaguya Ōtsutsuki', title: 'Matka Czakry i Wymiarów', minLevel: 55, baseHp: 850, baseAtk: 65, icon: '🌕', setGroup: 'boss_kaguya'),
];

class BaseGearArchetype {
  final String baseName;
  final GearSlot slot;
  final int baseStat;
  final String setGroup;
  final String lore;
  final String icon;

  const BaseGearArchetype({
    required this.baseName,
    required this.slot,
    required this.baseStat,
    this.setGroup = 'none',
    required this.lore,
    required this.icon,
  });
}

const List<BaseGearArchetype> standardArchetypesPool = [
  BaseGearArchetype(slot: GearSlot.weapon, baseName: 'Standardowy Kunai', baseStat: 5, setGroup: 'none', lore: 'Podstawowe narzędzie każdego ninja.', icon: '🗡️'),
  BaseGearArchetype(slot: GearSlot.weapon, baseName: 'Shuriken Fūma', baseStat: 8, setGroup: 'none', lore: 'Wirujące śmiercionośne ostrza.', icon: '🥏'),
  BaseGearArchetype(slot: GearSlot.weapon, baseName: 'Krótki Miecz Tanto', baseStat: 14, setGroup: 'anbu', lore: 'Ostrze skrytobójców ANBU.', icon: '⚔️'),
  BaseGearArchetype(slot: GearSlot.weapon, baseName: 'Tasaki z Mgły', baseStat: 18, setGroup: 'none', lore: 'Ciężka broń sieczna.', icon: '🔪'),
  BaseGearArchetype(slot: GearSlot.weapon, baseName: 'Chidorigatana', baseStat: 24, setGroup: 'myoboku', lore: 'Doskonale przewodzi błyskawice.', icon: '⚡'),
  BaseGearArchetype(slot: GearSlot.armor, baseName: 'Szata Treningowa', baseStat: 4, setGroup: 'none', lore: 'Lekki płócienny strój.', icon: '🥋'),
  BaseGearArchetype(slot: GearSlot.armor, baseName: 'Kamizelka Jonina', baseStat: 14, setGroup: 'none', lore: 'Oficjalny pancerz taktyczny.', icon: '🦺'),
  BaseGearArchetype(slot: GearSlot.armor, baseName: 'Szata Myōboku', baseStat: 22, setGroup: 'myoboku', lore: 'Pancerz senjutsu.', icon: '👘'),
  BaseGearArchetype(slot: GearSlot.helmet, baseName: 'Ochraniacz Protektor', baseStat: 3, setGroup: 'none', lore: 'Symbol Twojej wioski.', icon: '🛡️'),
  BaseGearArchetype(slot: GearSlot.helmet, baseName: 'Maska Lisa ANBU', baseStat: 11, setGroup: 'anbu', lore: 'Zaciera tożsamość.', icon: '🎭'),
  BaseGearArchetype(slot: GearSlot.boots, baseName: 'Sandały Shinobi', baseStat: 3, setGroup: 'none', lore: 'Oparcie stóp na pniach.', icon: '🥾'),
  BaseGearArchetype(slot: GearSlot.boots, baseName: 'Geta Żabiego Mędrca', baseStat: 13, setGroup: 'myoboku', lore: 'Balans na śliskich skałach.', icon: '🪵'),
  BaseGearArchetype(slot: GearSlot.trinket, baseName: 'Amulet Konohy', baseStat: 4, setGroup: 'none', lore: 'Błogosławieństwo kaplicy.', icon: '📿'),
  BaseGearArchetype(slot: GearSlot.trinket, baseName: 'Pieczęć Przepływu', baseStat: 14, setGroup: 'anbu', lore: 'Ogranicza straty energii.', icon: '🔮'),
];

const List<BaseGearArchetype> bossExclusiveSetsPool = [
  BaseGearArchetype(slot: GearSlot.weapon, baseName: 'Pazur Kyūbi', baseStat: 34, setGroup: 'boss_kyubi', lore: 'Przesiąknięty furią Lisa.', icon: '🔥'),
  BaseGearArchetype(slot: GearSlot.armor, baseName: 'Płaszcz Czerwonej Czakry', baseStat: 28, setGroup: 'boss_kyubi', lore: 'Płonąca powłoka ogoniastego.', icon: '🧥'),
  BaseGearArchetype(slot: GearSlot.helmet, baseName: 'Grzywa Demona Kyūbi', baseStat: 20, setGroup: 'boss_kyubi', lore: 'Aura nieugiętej furii.', icon: '🦊'),
  BaseGearArchetype(slot: GearSlot.trinket, baseName: 'Pieczęć 8 Trygramów', baseStat: 22, setGroup: 'boss_kyubi', lore: 'Potęga woli w czystej postaci.', icon: '🌀'),
  BaseGearArchetype(slot: GearSlot.weapon, baseName: 'Ostrze Susanoo', baseStat: 48, setGroup: 'boss_susanoo', lore: 'Eteryczny oręż zniszczenia.', icon: '🗡️'),
  BaseGearArchetype(slot: GearSlot.armor, baseName: 'Żebrowy Pancerz Duszy', baseStat: 42, setGroup: 'boss_susanoo', lore: 'Niewzruszona obrona Uchiha.', icon: '🛡️'),
  BaseGearArchetype(slot: GearSlot.helmet, baseName: 'Maska Wojenna Madary', baseStat: 30, setGroup: 'boss_susanoo', lore: 'Pogardliwe spojrzenie dla wrogów.', icon: '👺'),
  BaseGearArchetype(slot: GearSlot.boots, baseName: 'Kroki Wojny Susanoo', baseStat: 28, setGroup: 'boss_susanoo', lore: 'Kruszą twarde skały.', icon: '👢'),
  BaseGearArchetype(slot: GearSlot.weapon, baseName: 'Ostrze Martwych Kości', baseStat: 65, setGroup: 'boss_kaguya', lore: 'Popielaty dotyk zagłady.', icon: '🦴'),
  BaseGearArchetype(slot: GearSlot.armor, baseName: 'Jedwabna Szata Wymiarów', baseStat: 56, setGroup: 'boss_kaguya', lore: 'Tkanina z innych światów.', icon: '👘'),
  BaseGearArchetype(slot: GearSlot.helmet, baseName: 'Korona Bogini Królika', baseStat: 40, setGroup: 'boss_kaguya', lore: 'Wieniec Matki Czakry.', icon: '👑'),
  BaseGearArchetype(slot: GearSlot.trinket, baseName: 'Rdzeń Boskiego Drzewa', baseStat: 42, setGroup: 'boss_kaguya', lore: 'Początek wszelkiego życia.', icon: '🌳'),
];

class NinjaGear {
  final String name;
  final ItemRarity rarity;
  final GearSlot slot;
  final int baseStat;
  final List<GearAffix> affixes;
  final String setGroup;
  final bool isSoulbound;
  final int upgradeLevel;
  final String icon;

  const NinjaGear({
    required this.name,
    required this.rarity,
    required this.slot,
    required this.baseStat,
    this.affixes = const [],
    this.setGroup = 'none',
    this.isSoulbound = false,
    this.upgradeLevel = 0,
    this.icon = '🎒',
  });

  bool get isBossSet => setGroup.startsWith('boss_');

  NinjaGear copyWith({
    String? name,
    ItemRarity? rarity,
    GearSlot? slot,
    int? baseStat,
    List<GearAffix>? affixes,
    String? setGroup,
    bool? isSoulbound,
    int? upgradeLevel,
    String? icon,
  }) {
    return NinjaGear(
      name: name ?? this.name,
      rarity: rarity ?? this.rarity,
      slot: slot ?? this.slot,
      baseStat: baseStat ?? this.baseStat,
      affixes: affixes ?? this.affixes,
      setGroup: setGroup ?? this.setGroup,
      isSoulbound: isSoulbound ?? this.isSoulbound,
      upgradeLevel: upgradeLevel ?? this.upgradeLevel,
      icon: icon ?? this.icon,
    );
  }

  int get effectiveStat => baseStat + (upgradeLevel * (2 + rarity.index));
  String get displayName => upgradeLevel > 0 ? '$name +$upgradeLevel' : name;

  int get marketValue {
    int rarityMultiplier;
    switch (rarity) {
      case ItemRarity.common: rarityMultiplier = 1; break;
      case ItemRarity.rare: rarityMultiplier = 3; break;
      case ItemRarity.epic: rarityMultiplier = 7; break;
      case ItemRarity.legendary: rarityMultiplier = 16; break;
    }

    int value = (baseStat * 6 * rarityMultiplier);
    value += affixes.length * (40 * rarityMultiplier);
    value += (upgradeLevel * (upgradeLevel + 1) * 35);
    if (isBossSet) value = (value * 1.8).round();
    return max(25, value);
  }

  int get sellPrice => (marketValue * 0.4).round();
  int get sealingCost => (marketValue * 0.6).round();

  int getAffixValue(AffixType type) {
    int sum = 0;
    for (var a in affixes) {
      if (a.type == type) sum += a.value;
    }
    return sum;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'rarity': rarity.index,
    'slot': slot.index,
    'baseStat': baseStat,
    'affixes': affixes.map((a) => a.toJson()).toList(),
    'setGroup': setGroup,
    'isSoulbound': isSoulbound,
    'upgradeLevel': upgradeLevel,
    'icon': icon,
  };

  factory NinjaGear.fromJson(Map<String, dynamic> json) => NinjaGear(
    name: json['name'],
    rarity: ItemRarity.values[json['rarity'] ?? 0],
    slot: GearSlot.values[json['slot'] ?? 0],
    baseStat: json['baseStat'] ?? 5,
    affixes: (json['affixes'] as List?)?.map((a) => GearAffix.fromJson(a)).toList() ?? const [],
    setGroup: json['setGroup'] ?? 'none',
    isSoulbound: json['isSoulbound'] ?? false,
    upgradeLevel: json['upgradeLevel'] ?? 0,
    icon: json['icon'] ?? '🎒',
  );

  Color get color {
    switch (rarity) {
      case ItemRarity.common: return const Color(0xFFCFD8DC);
      case ItemRarity.rare: return const Color(0xFF29B6F6);
      case ItemRarity.epic: return const Color(0xFFBA68C8);
      case ItemRarity.legendary: return const Color(0xFFFFD54F);
    }
  }

  Color get borderColor {
    if (isBossSet) return const Color(0xFFFF1744);
    if (rarity == ItemRarity.legendary) return const Color(0xFFFFD700);
    return isSoulbound ? const Color(0xFF81C784) : color.withAlpha(140);
  }

  double get borderWidth {
    if (isBossSet) return 2.2;
    if (rarity == ItemRarity.legendary) return 2.0;
    return 1.4;
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
  Consumable(id: 'c_pill', name: 'Pigułka Żywnościowa', description: 'Odnawia czakrę procentowo.', statBonusText: '🌀 +35% CP', type: ConsumableType.healCpPercent, value: 35, price: 40, icon: '💊'),
  Consumable(id: 'c_dango', name: 'Słodkie Dango', description: 'Odnawia siły witalne procentowo.', statBonusText: '❤️ +25% HP', type: ConsumableType.healHpPercent, value: 25, price: 30, icon: '🍡'),
  Consumable(id: 'c_bandage', name: 'Bandaże Uciskowe', description: 'Zatamowują rany i krwawienie.', statBonusText: '❤️ +45% HP', type: ConsumableType.healHpPercent, value: 45, price: 55, icon: '🩹'),
  Consumable(id: 'c_ramen', name: 'Ramen Ichiraku', description: 'Pełna regeneracja oraz stały wzrost witalności.', statBonusText: '❤️/🌀 100% & Baza +8', type: ConsumableType.ramenRestore, value: 8, price: 260, icon: '🍜'),
  Consumable(id: 'c_power_pill', name: 'Pigułka Siły', description: 'Stały bonus do obrażeń fizycznych.', statBonusText: '⚔️ +4 Ataku', type: ConsumableType.buffAtk, value: 4, price: 180, icon: '⚡'),
  Consumable(id: 'c_kibaku', name: 'Pieczęć Wybuchowa', description: 'Bezpośrednie obrażenia skalowane poziomem.', statBonusText: '💥 35 + (4xLvl)', type: ConsumableType.directDmg, value: 35, price: 65, icon: '🏷️'),
  Consumable(id: 'c_smoke', name: 'Bomba Dymna', description: 'Natychmiastowa ucieczka ze standardowej walki.', statBonusText: '💨 Ucieczka 100%', type: ConsumableType.smokeEscape, value: 0, price: 45, icon: '💨'),
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
      case JutsuEffect.freeze: return 'Zamrożenie: Wróg traci turę';
      case JutsuEffect.stun: return 'Ogłuszenie: Wróg traci turę';
      case JutsuEffect.lifesteal: return 'Wyssanie: Odzyskuje HP równe $effectValue% obrażeń';
      case JutsuEffect.shock: return 'Paraliż: Przeciwnik traci turę';
      case JutsuEffect.none: return 'Czyste uderzenie czakry';
    }
  }
}

const List<Jutsu> allJutsuPool = [
  Jutsu(id: 'j_taijutsu', name: 'Podstawowe Taijutsu', chakraCost: 0, powerMultiplier: 1, costRyo: 0, color: Color(0xFF78909C)),
  Jutsu(id: 'j_konoha_senpuu', name: 'Konoha Senpū', chakraCost: 12, powerMultiplier: 2, costRyo: 220, color: Color(0xFF66BB6A), effect: JutsuEffect.stun, effectDuration: 1),
  Jutsu(id: 'j_katon', name: 'Katon: Goukakyu', chakraCost: 20, powerMultiplier: 2, costRyo: 320, color: Color(0xFFFF7043), effect: JutsuEffect.burn, effectDuration: 2, effectValue: 10),
  Jutsu(id: 'j_rasengan', name: 'Rasengan', chakraCost: 35, powerMultiplier: 3, costRyo: 800, color: Color(0xFF42A5F5)),
  Jutsu(id: 'j_amaterasu', name: 'Amaterasu', chakraCost: 65, powerMultiplier: 5, costRyo: 2200, color: Color(0xFF7E57C2), effect: JutsuEffect.burn, effectDuration: 4, effectValue: 30),
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
    this.icon = '👤',
    this.critRate = 0,
    this.dodgeRate = 0,
    this.armorPierce = 0,
    this.flatBlock = 0,
  });
}

const List<EnemyTemplate> standardEnemiesPool = [
  EnemyTemplate(id: 'e_dog', name: 'Dziki Ninja-Pies', title: 'Zdziczały Ninken', baseHp: 32, baseAtk: 8, locationId: 'loc_gate', icon: '🐕', dodgeRate: 5),
  EnemyTemplate(id: 'e_bandit', name: 'Bandyta z Kraju Fal', title: 'Pospolity Rabuś', baseHp: 40, baseAtk: 10, locationId: 'loc_gate', icon: '🥷', critRate: 5),
  EnemyTemplate(id: 'e_rain', name: 'Ninja Deszczu', title: 'Nuke-nin z Amegakure', baseHp: 58, baseAtk: 13, locationId: 'loc_forest', icon: '🌧️', dodgeRate: 8, armorPierce: 8),
  EnemyTemplate(id: 'e_rock', name: 'Szpieg Skały', title: 'Zwiadowca z Iwagakure', baseHp: 68, baseAtk: 14, locationId: 'loc_forest', icon: '🗿', flatBlock: 5),
  EnemyTemplate(id: 'e_mercenary', name: 'Zabójca z Mgły', title: 'Płatny Morderca', baseHp: 85, baseAtk: 18, locationId: 'loc_waves', icon: '⚔️', critRate: 10, armorPierce: 12),
  EnemyTemplate(id: 'e_zetsu', name: 'Klon Białego Zetsu', title: 'Infiltrator Mokuton', baseHp: 105, baseAtk: 21, locationId: 'loc_valley', icon: '🪴', dodgeRate: 10),
  EnemyTemplate(id: 'e_akatsuki_agent', name: 'Agent Akatsuki', title: 'Posłaniec Zagłady', baseHp: 135, baseAtk: 26, locationId: 'loc_akatsuki', icon: '🩸', critRate: 15, armorPierce: 20),
];

const List<EnemyTemplate> bossesPool = [
  EnemyTemplate(id: 'b_zabuza', name: 'Zabuza Momochi', title: 'Demon Ukrytej Mgły', baseHp: 175, baseAtk: 26, locationId: 'loc_waves', isBoss: true, icon: '🗡️', critRate: 15, dodgeRate: 12, armorPierce: 15),
  EnemyTemplate(id: 'b_gaara', name: 'Gaara Pustyni', title: 'Głos Shukaku', baseHp: 245, baseAtk: 30, locationId: 'loc_valley', isBoss: true, icon: '🏺', flatBlock: 12, armorPierce: 14),
  EnemyTemplate(id: 'b_itachi', name: 'Itachi Uchiha', title: 'Mistrz Sharingana', baseHp: 340, baseAtk: 38, locationId: 'loc_akatsuki', isBoss: true, icon: '👁️', critRate: 20, dodgeRate: 20, armorPierce: 25),
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
  final String icon;
  final int critRate;
  final int dodgeRate;

  const ExamStage({
    required this.targetRankIndex,
    required this.rankTitle,
    required this.requiredLevel,
    required this.examinerName,
    required this.examinerTitle,
    required this.hp,
    required this.atk,
    required this.lore,
    required this.icon,
    this.critRate = 5,
    this.dodgeRate = 5,
  });
}

const List<ExamStage> shinobiExams = [
  ExamStage(targetRankIndex: 1, rankTitle: 'Genin', requiredLevel: 4, examinerName: 'Iruka Umino', examinerTitle: 'Instruktor Akademii Ninja', hp: 90, atk: 14, lore: '„Pokaż mi skupienie!”', icon: '👨🏻‍🏫', critRate: 5, dodgeRate: 5),
  ExamStage(targetRankIndex: 2, rankTitle: 'Chūnin', requiredLevel: 12, examinerName: 'Ibiki Morino', examinerTitle: 'Dowódca Śledczy', hp: 160, atk: 22, lore: '„Sprawdzę Twój próg bólu!”', icon: '🕵️', critRate: 8, dodgeRate: 8),
  ExamStage(targetRankIndex: 3, rankTitle: 'Tokubetsu Jōnin', requiredLevel: 22, examinerName: 'Anko Mitarashi', examinerTitle: 'Egzaminatorka Lasu Śmierci', hp: 240, atk: 29, lore: '„Mordercze tempo!”', icon: '🐍', critRate: 12, dodgeRate: 12),
  ExamStage(targetRankIndex: 4, rankTitle: 'Jōnin Bojowy', requiredLevel: 35, examinerName: 'Kakashi Hatake', examinerTitle: 'Kopiujący Ninja', hp: 350, atk: 38, lore: '„Test dzwonków.”', icon: '⚡', critRate: 18, dodgeRate: 16),
  ExamStage(targetRankIndex: 5, rankTitle: 'Elita ANBU', requiredLevel: 48, examinerName: 'Danzō Shimura', examinerTitle: 'Dowódca Korzenia', hp: 460, atk: 47, lore: '„Ciemność i bezwzględność.”', icon: '🥷', critRate: 20, dodgeRate: 18),
  ExamStage(targetRankIndex: 6, rankTitle: 'Legendarny Sannin / Kage', requiredLevel: 60, examinerName: 'Jiraiya', examinerTitle: 'Żabi Mędrzec', hp: 600, atk: 56, lore: '„Wola Ognia!”', icon: '🐸', critRate: 24, dodgeRate: 20),
];

enum MissionType { killCount, bossHunt, itemSupply }

class ShinobiMission {
  final String id;
  final String rank;
  final int minRankIndex;
  final String locationId;
  final String targetEnemyId;
  final String title;
  final String desc;
  final int requiredCount;
  final int rewardRyo;
  final int rewardExp;
  final MissionType type;
  final String? supplyItemId;

  const ShinobiMission({
    required this.id,
    required this.rank,
    required this.minRankIndex,
    required this.locationId,
    required this.targetEnemyId,
    required this.title,
    required this.desc,
    required this.requiredCount,
    required this.rewardRyo,
    required this.rewardExp,
    this.type = MissionType.killCount,
    this.supplyItemId,
  });
}

const List<ShinobiMission> allMissionsPool = [
  ShinobiMission(id: 'm_d1', rank: 'D', minRankIndex: 0, locationId: 'loc_gate', targetEnemyId: 'e_dog', title: 'Oczyszczenie Bramy', desc: 'Wyeliminuj 3 Dzikie Psy terroryzujące obrzeża.', requiredCount: 3, rewardRyo: 110, rewardExp: 60),
  ShinobiMission(id: 'm_d2', rank: 'D', minRankIndex: 0, locationId: 'loc_gate', targetEnemyId: 'e_bandit', title: 'Ujarzmianie Rabusiów', desc: 'Pokonaj 4 Pospolitych Rabusiów przy trakcie.', requiredCount: 4, rewardRyo: 140, rewardExp: 80),
  ShinobiMission(id: 'm_d3', rank: 'D', minRankIndex: 0, locationId: 'loc_gate', targetEnemyId: '', title: 'Dostawa Rudy dla Kowala', desc: 'Dostarcz 2 Rudy Żelaza Czakry.', requiredCount: 2, rewardRyo: 160, rewardExp: 90, type: MissionType.itemSupply, supplyItemId: matIronOre),
  ShinobiMission(id: 'm_c1', rank: 'C', minRankIndex: 2, locationId: 'loc_forest', targetEnemyId: 'e_rain', title: 'Infiltracja Lasu Śmierci', desc: 'Zneutralizuj 5 Nuke-ninów z Amegakure.', requiredCount: 5, rewardRyo: 300, rewardExp: 180),
  ShinobiMission(id: 'm_c2', rank: 'C', minRankIndex: 2, locationId: 'loc_forest', targetEnemyId: 'e_rock', title: 'Zwiadowcy Skały', desc: 'Eliminacja 5 szpiegów z Iwagakure.', requiredCount: 5, rewardRyo: 340, rewardExp: 210),
  ShinobiMission(id: 'm_b1', rank: 'B', minRankIndex: 3, locationId: 'loc_waves', targetEnemyId: 'e_mercenary', title: 'Most Tenkū pod Ostrzałem', desc: 'Pokonaj 6 Zabójców z Mgły.', requiredCount: 6, rewardRyo: 600, rewardExp: 420),
  ShinobiMission(id: 'm_b2', rank: 'B', minRankIndex: 3, locationId: 'loc_waves', targetEnemyId: 'b_zabuza', title: 'List Gończy: Zabuza Momochi', desc: 'Pokonaj Demona Ukrytej Mgły.', requiredCount: 1, rewardRyo: 900, rewardExp: 650, type: MissionType.bossHunt),
  ShinobiMission(id: 'm_a1', rank: 'A', minRankIndex: 4, locationId: 'loc_akatsuki', targetEnemyId: 'e_akatsuki_agent', title: 'Kres Cienia Akatsuki', desc: 'Zneutralizuj 7 Posłańców Zagłady.', requiredCount: 7, rewardRyo: 1200, rewardExp: 900),
  ShinobiMission(id: 'm_a2', rank: 'A', minRankIndex: 4, locationId: 'loc_valley', targetEnemyId: 'b_gaara', title: 'Ujarzmienie Pustynnego Demona', desc: 'Powstrzymaj Gaarę w Dolinie Końca.', requiredCount: 1, rewardRyo: 1500, rewardExp: 1100, type: MissionType.bossHunt),
  ShinobiMission(id: 'm_s1', rank: 'S', minRankIndex: 5, locationId: 'loc_akatsuki', targetEnemyId: 'b_itachi', title: 'Eksterminacja Cienia: Itachi', desc: 'Pokonaj Mistrza Mangekyō Sharingana.', requiredCount: 1, rewardRyo: 2800, rewardExp: 1800, type: MissionType.bossHunt),
];
