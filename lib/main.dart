import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const ShinobiLooterApp());

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

const NinjaGear defaultStarterWeapon = NinjaGear(name: 'Podstawowy Kunai', rarity: ItemRarity.common, slot: GearSlot.weapon, baseStat: 5, isSoulbound: true, icon: '🗡️');
const NinjaGear defaultStarterArmor = NinjaGear(name: 'Szata Treningowa Genina', rarity: ItemRarity.common, slot: GearSlot.armor, baseStat: 4, isSoulbound: true, icon: '🥋');
const NinjaGear defaultStarterHelmet = NinjaGear(name: 'Ochraniacz Protektor', rarity: ItemRarity.common, slot: GearSlot.helmet, baseStat: 3, isSoulbound: true, icon: '🛡️');
const NinjaGear defaultStarterBoots = NinjaGear(name: 'Sandały Shinobi', rarity: ItemRarity.common, slot: GearSlot.boots, baseStat: 3, isSoulbound: true, icon: '🥾');
const NinjaGear defaultStarterTrinket = NinjaGear(name: 'Amulet Konohy', rarity: ItemRarity.common, slot: GearSlot.trinket, baseStat: 3, isSoulbound: true, icon: '📿');

class ShinobiLooterApp extends StatelessWidget {
  const ShinobiLooterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shinobi Lootr',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0C0807),
        dialogBackgroundColor: const Color(0xFF1E1412),
        cardColor: const Color(0xFF1F1613),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE65100),
          secondary: Color(0xFFFF8F00),
          surface: Color(0xFF1E1412),
        ),
      ),
      home: const StartMenuScreen(),
    );
  }
}

class StartMenuScreen extends StatefulWidget {
  const StartMenuScreen({super.key});

  @override
  State<StartMenuScreen> createState() => _StartMenuScreenState();
}

class _StartMenuScreenState extends State<StartMenuScreen> {
  bool hasExistingSave = false;

  @override
  void initState() {
    super.initState();
    _checkSave();
  }

  Future<void> _checkSave() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hasExistingSave = prefs.containsKey('ninjaExp') || prefs.containsKey('hp');
    });
  }

  Future<void> _startNewGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ShinobiScreen(isNewGame: true)),
    );
  }

  void _continueGame() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ShinobiScreen(isNewGame: false)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0706),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2D150B), Color(0xFF0F0A08), Color(0xFF140D0B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 54)),
                    const SizedBox(height: 12),
                    const Text(
                      'SHINOBI LOOTR',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.5,
                        color: Color(0xFFFFB74D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('Droga Ninja i Legendarnego Łupu', style: TextStyle(fontSize: 13, color: Colors.white60)),
                    const SizedBox(height: 48),
                    if (hasExistingSave) ...[
                      SizedBox(
                        width: 240,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE65100),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _continueGame,
                          child: const Text('Kontynuuj Grę', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: 240,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasExistingSave ? const Color(0xFF3E2723) : const Color(0xFFE65100),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (hasExistingSave) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Nowa Gra'),
                                content: const Text('Rozpoczęcie nowej gry nadpisze obecny postęp. Na pewno chcesz zacząć od nowa?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _startNewGame();
                                    },
                                    child: const Text('Tak, zacznij od nowa'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            _startNewGame();
                          }
                        },
                        child: const Text('Nowa Gra', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShinobiScreen extends StatefulWidget {
  final bool isNewGame;
  const ShinobiScreen({super.key, required this.isNewGame});

  @override
  State<ShinobiScreen> createState() => _ShinobiScreenState();
}

class _ShinobiScreenState extends State<ShinobiScreen> {
  final Random _rng = Random();

  bool inVillage = true;
  String currentSelectedLocationId = 'loc_gate';

  int hp = 100;
  int baseMaxHp = 100;
  int chakra = 80;
  int baseMaxChakra = 80;

  int bonusAtk = 0;
  int ryo = 80;
  int ninjaExp = 0;
  int passedRankIndex = 0;
  bool isLoading = true;

  int? activeMissionIndex;
  int currentMissionKills = 0;
  Set<String> completedMissionsHistory = {};

  Map<String, int> bag = {'c_pill': 2, 'c_dango': 1, 'c_kibaku': 1, 'c_smoke': 1};
  Map<String, int> sealedBag = {};
  Map<String, int> craftingBag = {matIronOre: 2, matDungeonKey: 1};
  List<NinjaGear> equipmentStash = [];

  int vitalTrainingCount = 0;
  int dungeonCooldownTimestamp = 0;

  List<Jutsu> equippedJutsu = [allJutsuPool[0]];
  List<Jutsu> knownJutsu = [allJutsuPool[0]];

  NinjaGear currentWeapon = defaultStarterWeapon;
  NinjaGear currentArmor = defaultStarterArmor;
  NinjaGear currentHelmet = defaultStarterHelmet;
  NinjaGear currentBoots = defaultStarterBoots;
  NinjaGear currentTrinket = defaultStarterTrinket;

  final List<String> log = ['Witaj w Konohagakure! Wybierz strefę w menu, aby rozpocząć rajd.'];

  static const int softCapLevel = 65;

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
    return (70 * pow(lvl, 1.85) + 40 * lvl).floor();
  }

  int get expForNextLevel => level >= softCapLevel ? expRequiredForLevel(softCapLevel) : expRequiredForLevel(level + 1);

  String get ninjaRank {
    switch (passedRankIndex) {
      case 6: return 'Legendarny Sannin / Kage';
      case 5: return 'Elita ANBU (Korzeń)';
      case 4: return 'Jōnin Bojowy';
      case 3: return 'Tokubetsu Jōnin';
      case 2: return 'Chūnin';
      case 1: return 'Genin';
      default: return 'Nowicjusz Akademii';
    }
  }

  Color get rankColor {
    switch (passedRankIndex) {
      case 6: return const Color(0xFFFFD54F);
      case 5: return const Color(0xFFFF4081);
      case 4: return const Color(0xFFFF5252);
      case 3: return const Color(0xFFBA68C8);
      case 2: return const Color(0xFF448AFF);
      case 1: return const Color(0xFF69F0AE);
      default: return const Color(0xFF90A4AE);
    }
  }

  List<NinjaGear> get equippedList => [currentWeapon, currentArmor, currentHelmet, currentBoots, currentTrinket];

  int sumAffix(AffixType type) {
    int total = 0;
    for (var g in equippedList) {
      total += g.getAffixValue(type);
    }
    return total;
  }

  int get maxHp => baseMaxHp + sumAffix(AffixType.bonusHp);
  int get maxChakra => baseMaxChakra + sumAffix(AffixType.bonusChakra);

  int get totalCritRate => sumAffix(AffixType.critRate) + (activeSetCounts['boss_kyubi'] != null && activeSetCounts['boss_kyubi']! >= 4 ? 25 : 0);
  int get totalDodgeRate => sumAffix(AffixType.dodgeRate) + (activeSetCounts['boss_susanoo'] != null && activeSetCounts['boss_susanoo']! >= 2 ? 10 : 0);
  int get totalArmorPierce => sumAffix(AffixType.armorPierce) + (activeSetCounts['boss_susanoo'] != null && activeSetCounts['boss_susanoo']! >= 4 ? 20 : 0);
  int get totalLifeSteal => sumAffix(AffixType.lifeSteal) + (activeSetCounts['boss_kyubi'] != null && activeSetCounts['boss_kyubi']! >= 2 ? 12 : 0);
  int get totalHpRegen => sumAffix(AffixType.hpRegen) + (activeSetCounts['boss_kyubi'] != null && activeSetCounts['boss_kyubi']! >= 4 ? 15 : 0);
  int get totalChakraRegen => sumAffix(AffixType.chakraRegen) + (activeSetCounts['boss_kaguya'] != null && activeSetCounts['boss_kaguya']! >= 2 ? 20 : 0);

  Map<String, int> get activeSetCounts {
    Map<String, int> counts = {};
    for (var gear in equippedList) {
      if (gear.setGroup != 'none') {
        counts[gear.setGroup] = (counts[gear.setGroup] ?? 0) + 1;
      }
    }
    return counts;
  }

  int get setBonusAtk {
    int bonus = 0;
    activeSetCounts.forEach((setGroup, count) {
      if (setGroup == 'anbu' && count >= 2) bonus += 6;
      if (setGroup == 'myoboku' && count >= 2) bonus += 10;
      if (setGroup == 'boss_kyubi' && count >= 2) bonus += 15;
      if (setGroup == 'boss_kaguya' && count >= 4) bonus += 35;
      if (count >= 4) bonus += 14;
    });
    return bonus;
  }

  int get setBonusDef {
    int bonus = 0;
    activeSetCounts.forEach((setGroup, count) {
      if (setGroup == 'anbu' && count >= 2) bonus += 5;
      if (setGroup == 'myoboku' && count >= 2) bonus += 8;
      if (setGroup == 'boss_susanoo' && count >= 2) bonus += 20;
      if (count >= 4) bonus += 12;
    });
    return bonus;
  }

  int get totalAttack => currentWeapon.effectiveStat + currentTrinket.effectiveStat + bonusAtk + setBonusAtk + (level * 2);
  int get totalDefense => currentArmor.effectiveStat + currentHelmet.effectiveStat + currentBoots.effectiveStat + setBonusDef;

  @override
  void initState() {
    super.initState();
    if (widget.isNewGame) {
      setState(() => isLoading = false);
    } else {
      _loadGameData();
    }
  }

  Future<void> _loadGameData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      baseMaxHp = prefs.getInt('baseMaxHp') ?? prefs.getInt('maxHp') ?? 100;
      baseMaxChakra = prefs.getInt('baseMaxChakra') ?? prefs.getInt('maxChakra') ?? 80;
      hp = prefs.getInt('hp') ?? baseMaxHp;
      chakra = prefs.getInt('chakra') ?? baseMaxChakra;
      bonusAtk = prefs.getInt('bonusAtk') ?? 0;
      ryo = prefs.getInt('ryo') ?? 80;
      ninjaExp = prefs.getInt('ninjaExp') ?? 0;
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

      final stashJson = prefs.getString('equipmentStash');
      if (stashJson != null) {
        final List decodedList = jsonDecode(stashJson);
        equipmentStash = decodedList.map((item) => NinjaGear.fromJson(item)).toList();
      }

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
    await prefs.setInt('baseMaxHp', baseMaxHp);
    await prefs.setInt('chakra', chakra);
    await prefs.setInt('baseMaxChakra', baseMaxChakra);
    await prefs.setInt('bonusAtk', bonusAtk);
    await prefs.setInt('ryo', ryo);
    await prefs.setInt('ninjaExp', ninjaExp);
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
    await prefs.setString('equipmentStash', jsonEncode(equipmentStash.map((i) => i.toJson()).toList()));
    await prefs.setString('currentWeapon', jsonEncode(currentWeapon.toJson()));
    await prefs.setString('currentArmor', jsonEncode(currentArmor.toJson()));
    await prefs.setString('currentHelmet', jsonEncode(currentHelmet.toJson()));
    await prefs.setString('currentBoots', jsonEncode(currentBoots.toJson()));
    await prefs.setString('currentTrinket', jsonEncode(currentTrinket.toJson()));
    await prefs.setStringList('knownJutsuIds', knownJutsu.map((j) => j.id).toList());
    await prefs.setStringList('equippedJutsuIds', equippedJutsu.map((j) => j.id).toList());
  }

  void showActionBlockedMessage(String msg) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: 36,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFC62828),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 12, offset: Offset(0, 4)),
              ],
              border: Border.all(color: Colors.white24, width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    msg,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (entry.mounted) entry.remove();
    });
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
      if (log.length > 30) log.removeLast();
    });
    _saveGameData();
  }

  void returnToVillage({bool fallenInBattle = false}) {
    setState(() {
      inVillage = true;
      hp = maxHp;
      chakra = maxChakra;

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
      addLog('💀 Porażka w terenie! Utracono rynsztunek bez pieczęci.');
    } else {
      addLog('⛩️ Bezpieczny powrót do bram Konohagakure.');
    }
    _saveGameData();
  }

  void leaveVillage(ShinobiLocation location) {
    if (level < location.minLevel) {
      showActionBlockedMessage('🚫 Wymagany poziom ${location.minLevel} dla tej strefy!');
      return;
    }
    setState(() {
      inVillage = false;
      currentSelectedLocationId = location.id;
    });
    addLog('🍃 Wyruszasz do: ${location.name}!');
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
        case ConsumableType.healHpPercent:
          int restoreHp = (maxHp * item.value / 100).round();
          hp = min(maxHp, hp + restoreHp);
          addLog('${item.icon} Użyto [${item.name}]: +$restoreHp HP.');
          break;
        case ConsumableType.healCpPercent:
          int restoreCp = (maxChakra * item.value / 100).round();
          chakra = min(maxChakra, chakra + restoreCp);
          addLog('${item.icon} Użyto [${item.name}]: +$restoreCp CP.');
          break;
        case ConsumableType.ramenRestore:
          baseMaxHp += item.value;
          baseMaxChakra += item.value;
          hp = maxHp;
          chakra = maxChakra;
          addLog('${item.icon} Pełnia sił! Limity bazowe wzrosły o +${item.value}!');
          break;
        case ConsumableType.buffAtk:
          bonusAtk += item.value;
          addLog('${item.icon} Zwiększono atak bazowy o ${item.value}.');
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

    if (totalHpRegen > 0) hp = min(maxHp, hp + totalHpRegen);
    if (totalChakraRegen > 0) chakra = min(maxChakra, chakra + totalChakraRegen);

    final loc = shinobiLocations.firstWhere((l) => l.id == currentSelectedLocationId);
    final roll = _rng.nextInt(100);

    if (roll < 14) {
      const emptyMessages = [
        '🌿 Spokojna okolica. Wokół panuje cisza.',
        '🍃 Wędrówka mija bez echa, wiatr szumi w koronach.',
        '🌳 Cisza i spokój. Łapiesz krótki oddech.',
        '🌲 Pusta ścieżka, patrolujesz teren bez zakłóceń.'
      ];
      addLog(emptyMessages[_rng.nextInt(emptyMessages.length)]);
    } else if (roll < 28) {
      final subRoll = _rng.nextInt(100);
      if (subRoll < 55) {
        final List<String> commonDrops = ['c_pill', 'c_dango', 'c_bandage'];
        final picked = commonDrops[_rng.nextInt(commonDrops.length)];
        bag[picked] = (bag[picked] ?? 0) + 1;
        final item = allConsumables.firstWhere((c) => c.id == picked);
        addLog('🌿 Zwiadowcze znalezisko: ${item.icon} ${item.name}!');
      } else {
        String mat = matIronOre;
        if (loc.id == 'loc_waves' || loc.id == 'loc_valley') {
          mat = matSteel;
        } else if (loc.id == 'loc_akatsuki') {
          mat = matCrystal;
        }
        addCraftingMaterial(mat, 1);
        final matInfo = craftingMaterials[mat]!;
        addLog('⛏️ Odkryto żyłę czakry: ${matInfo.icon} ${matInfo.name}!');
      }
      _saveGameData();
    } else if (roll < 34) {
      _encounterWanderingMerchant();
    } else if (roll < 62) {
      final locationEnemies = standardEnemiesPool.where((e) => e.locationId == currentSelectedLocationId).toList();
      final enemy = locationEnemies.isNotEmpty ? locationEnemies[_rng.nextInt(locationEnemies.length)] : standardEnemiesPool[0];

      final pRoll = _rng.nextInt(100);
      EnemyPrefix p = pRoll < 55 ? EnemyPrefix.weak : (pRoll < 85 ? EnemyPrefix.normal : EnemyPrefix.strong);
      _startBattleWithEnemy(enemy, forcePrefix: p);
    } else if (roll < 76) {
      final locationBosses = bossesPool.where((b) => b.locationId == currentSelectedLocationId).toList();
      final boss = locationBosses.isNotEmpty ? locationBosses[_rng.nextInt(locationBosses.length)] : bossesPool[0];
      addLog('⚠️ ${loc.name}: Pojawił się boss -> ${boss.name}!');
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

  void _encounterWanderingMerchant() {
    addLog('💰 Spotkano Wędrownego Kupca na szlaku!');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setMerchantState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1C14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFFFD54F), width: 1.2)),
            title: const Row(
              children: [
                Text('🛒 ', style: TextStyle(fontSize: 22)),
                Expanded(child: Text('Wędrowny Kupczenko', style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 16))),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('„Masz ryo? Mam towary z najdalszych zakątków świata!”', style: TextStyle(fontSize: 11, color: Colors.white70, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 10),
                    const Text('Kup zapasy:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D))),
                    const SizedBox(height: 6),
                    ...allConsumables.map((c) {
                      return ListTile(
                        dense: true,
                        leading: Text(c.icon, style: const TextStyle(fontSize: 20)),
                        title: Text(c.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        subtitle: Text('Cena: ${c.price} Ryo | ${c.statBonusText}', style: const TextStyle(fontSize: 10, color: Colors.white60)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                          onPressed: () {
                            if (ryo < c.price) {
                              showActionBlockedMessage('💰 Za mało Ryo!');
                              return;
                            }
                            setState(() {
                              ryo -= c.price;
                              bag[c.id] = (bag[c.id] ?? 0) + 1;
                            });
                            _saveGameData();
                            setMerchantState(() {});
                            addLog('🛒 Kupiono [${c.name}] od kupca.');
                          },
                          child: const Text('Kup', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      );
                    }),
                    const Divider(color: Colors.white12),
                    const Text('Materiały i Klucze:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFD54F))),
                    const SizedBox(height: 6),
                    ListTile(
                      dense: true,
                      leading: const Text('🗝️', style: TextStyle(fontSize: 20)),
                      title: const Text('Klucz do Lochów', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Cena: 600 Ryo', style: TextStyle(fontSize: 10, color: Colors.white60)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B1FA2), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                        onPressed: () {
                          if (ryo < 600) {
                            showActionBlockedMessage('💰 Za mało Ryo!');
                            return;
                          }
                          setState(() {
                            ryo -= 600;
                            craftingBag[matDungeonKey] = (craftingBag[matDungeonKey] ?? 0) + 1;
                          });
                          _saveGameData();
                          setMerchantState(() {});
                          addLog('🛒 Kupiono Klucz do Lochów od kupca.');
                        },
                        child: const Text('Kup', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zakończ handel', style: TextStyle(color: Colors.grey)))],
          );
        },
      ),
    );
  }

  int _getSealingCost(ItemRarity rarity, bool isBossSet) {
    if (isBossSet) return 3000;
    switch (rarity) {
      case ItemRarity.common: return 200;
      case ItemRarity.rare: return 500;
      case ItemRarity.epic: return 1100;
      case ItemRarity.legendary: return 2500;
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
        title: const Row(
          children: [
            Text('🈴 ', style: TextStyle(fontSize: 22)),
            Expanded(child: Text('Mistrz Fūinjutsu', style: TextStyle(color: Color(0xFFFF8A80), fontWeight: FontWeight.bold, fontSize: 16))),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B1A1E),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFF8A80), width: 1.5),
                    ),
                    child: const Text('📜', style: TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '„Pieczętuję ekwipunek wieczną czakrą ochrony. Zapieczętowany rynsztunek nigdy nie przepadnie.”',
                  style: TextStyle(fontSize: 11, color: Colors.white70, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                if (unsealedSlots.isEmpty)
                  const Center(child: Text('Wszystkie przedmioty są już zapieczętowane!', style: TextStyle(color: Color(0xFF69F0AE), fontSize: 11)))
                else
                  ...unsealedSlots.entries.map((entry) {
                    final slot = entry.key;
                    final gear = entry.value;
                    final cost = gear.sealingCost;
                    String slotName = slot == GearSlot.weapon ? 'Broń' : (slot == GearSlot.armor ? 'Pancerz' : (slot == GearSlot.helmet ? 'Głowa' : (slot == GearSlot.boots ? 'Buty' : 'Talizman')));

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(gear.icon, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$slotName: ${gear.displayName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: gear.borderColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('Koszt: $cost Ryo', style: const TextStyle(fontSize: 10, color: Color(0xFFFFD54F))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB71C1C),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            onPressed: () {
                              if (ryo < cost) {
                                showActionBlockedMessage('💰 Za mało Ryo! Brakuje Ci ${cost - ryo} Ryo.');
                                return;
                              }
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
                            },
                            child: const Text('Pieczęć', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Odejdź', style: TextStyle(color: Colors.grey)))],
      ),
    );
  }

  void _encounterWanderingSage() {
    final unlearnedJutsu = allJutsuPool.where((j) => !knownJutsu.any((k) => k.id == j.id)).toList();
    if (unlearnedJutsu.isEmpty) {
      addLog('👴🏻 Spotkano Wędrownego Mędrca, ale znasz już wszystkie jego techniki.');
      return;
    }
    final offered = unlearnedJutsu[_rng.nextInt(unlearnedJutsu.length)];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1814),
        title: const Row(
          children: [
            Text('👴🏻 ', style: TextStyle(fontSize: 22)),
            Expanded(child: Text('Wędrowny Mędrzec', style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E261B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
              ),
              child: const Text('📜', style: TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 6),
            Text(
              '„Mogę zdradzić ci tajemnicę zwoju [${offered.name}] w zamian za ${offered.costRyo} Ryo.”',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(offered.effectDescription, style: const TextStyle(fontSize: 10, color: Color(0xFFFFCC80))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Odejdź', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
            onPressed: () {
              if (ryo < offered.costRyo) {
                showActionBlockedMessage('💰 Brakuje Ci ${offered.costRyo - ryo} Ryo!');
                return;
              }
              setState(() {
                ryo -= offered.costRyo;
                knownJutsu.add(offered);
              });
              _saveGameData();
              Navigator.pop(ctx);
              addLog('📜 Poznano nowe Jutsu: [${offered.name}]!');
            },
            child: const Text('Kup Zwój', style: TextStyle(fontWeight: FontWeight.bold)),
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
          final int healCost = 15 + (level * 3);
          final int vitalCost = (150 * pow(1.35, vitalTrainingCount)).floor();

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
                      title: const Text('Pełne Leczenie', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text('Odnawia HP i CP do 100% ($healCost Ryo)', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00695C)),
                        onPressed: () {
                          if (hp >= maxHp && chakra >= maxChakra) {
                            showActionBlockedMessage('✨ Masz już pełne zdrowie i czakrę!');
                            return;
                          }
                          if (ryo < healCost) {
                            showActionBlockedMessage('💰 Brakuje Ci ${healCost - ryo} Ryo!');
                            return;
                          }
                          setState(() {
                            ryo -= healCost;
                            hp = maxHp;
                            chakra = maxChakra;
                          });
                          _saveGameData();
                          setMedicState(() {});
                          addLog('🩺 Opatrzono rany (-$healCost Ryo).');
                        },
                        child: Text('$healCost Ryo', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const Divider(color: Colors.white12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Text('🧬', style: TextStyle(fontSize: 24)),
                      title: Text('Trening Witalności (#${vitalTrainingCount + 1})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('+10 Max HP i +10 Max CP (Baza)', style: TextStyle(fontSize: 11, color: Colors.white60)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                        onPressed: () {
                          if (ryo < vitalCost) {
                            showActionBlockedMessage('💰 Brakuje Ci ${vitalCost - ryo} Ryo!');
                            return;
                          }
                          setState(() {
                            ryo -= vitalCost;
                            vitalTrainingCount++;
                            baseMaxHp += 10;
                            baseMaxChakra += 10;
                            hp += 10;
                            chakra += 10;
                          });
                          _saveGameData();
                          setMedicState(() {});
                          addLog('✨ Rozwinięto witalność za $vitalCost Ryo.');
                        },
                        child: Text('$vitalCost Ryo', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const Divider(color: Colors.white12),
                    const Text('Kup zapasy na drogę:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D))),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: allConsumables.map((c) {
                        return ActionChip(
                          avatar: Text(c.icon),
                          label: Text('${c.name} (${c.price} Ryo)', style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            if (ryo < c.price) {
                              showActionBlockedMessage('💰 Brakuje Ci ${c.price - ryo} Ryo!');
                              return;
                            }
                            setState(() {
                              ryo -= c.price;
                              bag[c.id] = (bag[c.id] ?? 0) + 1;
                            });
                            _saveGameData();
                            setMedicState(() {});
                            addLog('📦 Zakupiono [${c.name}].');
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Wyjdź', style: TextStyle(color: Colors.grey)))],
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
                        Text('🪨 Ruda: ${craftingBag[matIronOre] ?? 0}', style: const TextStyle(fontSize: 11)),
                        Text('🧱 Stal: ${craftingBag[matSteel] ?? 0}', style: const TextStyle(fontSize: 11)),
                        Text('💎 Kryształ: ${craftingBag[matCrystal] ?? 0}', style: const TextStyle(fontSize: 11)),
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
                      int ryoCost = (45 * pow(1 + curLvl, 1.45) + (gear.rarity.index * 30)).round();

                      if (curLvl >= 6) {
                        neededMatId = matCrystal;
                      } else if (curLvl >= 3) {
                        neededMatId = matSteel;
                      }

                      final matInfo = craftingMaterials[neededMatId]!;
                      final int ownedMats = craftingBag[neededMatId] ?? 0;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141211),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: gear.borderColor, width: gear.borderWidth),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(gear.icon, style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 6),
                                    Text('$slotLabel: ${gear.displayName}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: gear.borderColor)),
                                  ],
                                ),
                                Text('Moc: +${gear.effectiveStat}', style: const TextStyle(fontSize: 11, color: Color(0xFF69F0AE), fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            if (isMax)
                              const Text('✨ Maksymalny poziom kuźniczy (+9)!', style: TextStyle(color: Color(0xFFFFD54F), fontSize: 11))
                            else ...[
                              Text('Wymaga: ${matInfo.icon} $neededMatCount ${matInfo.name} oraz $ryoCost Ryo', style: const TextStyle(fontSize: 10, color: Colors.white60)),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE65100),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  onPressed: () {
                                    if (isMax) {
                                      showActionBlockedMessage('✨ Przedmiot osiągnął maksimum (+9)!');
                                      return;
                                    }
                                    if (ryo < ryoCost) {
                                      showActionBlockedMessage('💰 Za mało Ryo! Brakuje Ci ${ryoCost - ryo} Ryo.');
                                      return;
                                    }
                                    if (ownedMats < neededMatCount) {
                                      showActionBlockedMessage('⚒️ Brak materiału: ${matInfo.name}!');
                                      return;
                                    }
                                    setState(() {
                                      ryo -= ryoCost;
                                      craftingBag[neededMatId] = ownedMats - neededMatCount;
                                      int successRate = curLvl < 3 ? 95 : (curLvl < 6 ? 75 : 55);
                                      bool success = _rng.nextInt(100) < successRate;

                                      NinjaGear upgraded = success ? gear.copyWith(upgradeLevel: curLvl + 1) : gear;
                                      if (success) {
                                        addLog('🔨 Sukces! ${gear.name} ulepszono na +${curLvl + 1}!');
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
                                  },
                                  child: Text('Kuj na +${curLvl + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Odejdź', style: TextStyle(color: Colors.grey)))],
          );
        },
      ),
    );
  }

  void _openEquipmentStashDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStashState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF191716),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFFFB74D), width: 1.2)),
            title: Row(
              children: [
                const Text('📦 ', style: TextStyle(fontSize: 22)),
                Expanded(child: Text('Plecak Ekwipunku (${equipmentStash.length}/10)', style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 16, fontWeight: FontWeight.bold))),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (equipmentStash.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Plecak z rynsztunkiem jest pusty.', style: TextStyle(fontSize: 12, color: Colors.white54)),
                      )
                    else
                      ...equipmentStash.asMap().entries.map((entry) {
                        final index = entry.key;
                        final gear = entry.value;
                        String slotName = gear.slot == GearSlot.weapon ? 'Broń' : (gear.slot == GearSlot.armor ? 'Pancerz' : (gear.slot == GearSlot.helmet ? 'Głowa' : (gear.slot == GearSlot.boots ? 'Buty' : 'Talizman')));

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141211),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: gear.borderColor, width: gear.borderWidth),
                          ),
                          child: Row(
                            children: [
                              Text(gear.icon, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('$slotName: ${gear.displayName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: gear.borderColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                    Text('Moc: +${gear.effectiveStat} | Wartość: ${gear.sellPrice} Ryo', style: const TextStyle(fontSize: 9, color: Colors.white70)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00695C), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4)),
                                onPressed: () {
                                  setState(() {
                                    NinjaGear oldGear;
                                    switch (gear.slot) {
                                      case GearSlot.weapon: oldGear = currentWeapon; currentWeapon = gear; break;
                                      case GearSlot.armor: oldGear = currentArmor; currentArmor = gear; break;
                                      case GearSlot.helmet: oldGear = currentHelmet; currentHelmet = gear; break;
                                      case GearSlot.boots: oldGear = currentBoots; currentBoots = gear; break;
                                      case GearSlot.trinket: oldGear = currentTrinket; currentTrinket = gear; break;
                                    }
                                    equipmentStash[index] = oldGear;
                                  });
                                  _saveGameData();
                                  setStashState(() {});
                                  addLog('✨ Założono ${gear.displayName} z plecaka.');
                                },
                                child: const Text('Załóż', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 4),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4)),
                                onPressed: () {
                                  final price = gear.sellPrice;
                                  setState(() {
                                    ryo += price;
                                    equipmentStash.removeAt(index);
                                  });
                                  _saveGameData();
                                  setStashState(() {});
                                  addLog('💰 Sprzedano z plecaka [${gear.displayName}] za +$price Ryo.');
                                },
                                child: const Text('Sprzedaj', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zamknij', style: TextStyle(color: Colors.grey)))],
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
          final bool hasPendingExam = passedRankIndex < 6 && level >= nextExam.requiredLevel;

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
                    if (passedRankIndex < 6) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
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
                                Row(
                                  children: [
                                    Text(nextExam.icon, style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 6),
                                    Text('Egzamin na ${nextExam.rankTitle}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: hasPendingExam ? const Color(0xFFFFD54F) : Colors.white70)),
                                  ],
                                ),
                                Text('Wymaga: Lvl ${nextExam.requiredLevel}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text('Egzaminator: ${nextExam.examinerName} (${nextExam.examinerTitle})', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                            const SizedBox(height: 6),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasPendingExam ? const Color(0xFFE65100) : const Color(0xFF37474F),
                                minimumSize: const Size(double.infinity, 34),
                              ),
                              onPressed: () {
                                if (!hasPendingExam) {
                                  showActionBlockedMessage('🚫 Osiągnij poziom ${nextExam.requiredLevel} na ten egzamin!');
                                  return;
                                }
                                Navigator.pop(ctx);
                                _startBattleWithEnemy(
                                  EnemyTemplate(
                                    id: 'exam',
                                    name: nextExam.examinerName,
                                    title: nextExam.examinerTitle,
                                    baseHp: nextExam.hp,
                                    baseAtk: nextExam.atk,
                                    locationId: '',
                                    isBoss: true,
                                    icon: nextExam.icon,
                                    critRate: nextExam.critRate,
                                    dodgeRate: nextExam.dodgeRate,
                                  ),
                                  isExamFight: true,
                                  examTargetRank: nextExam.targetRankIndex,
                                );
                              },
                              child: Text(hasPendingExam ? 'Przystąp do Egzaminu!' : 'Zablokowane (Wymaga Lvl ${nextExam.requiredLevel})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    const Text('Zlecenia Hokage:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFFFAB91))),
                    const SizedBox(height: 6),

                    if (activeMissionIndex != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFF141211), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF69F0AE).withAlpha(160))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Aktywna Misja: Ranga ${allMissionsPool[activeMissionIndex!].rank}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFFFD54F))),
                            Text(allMissionsPool[activeMissionIndex!].title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: currentMissionKills / allMissionsPool[activeMissionIndex!].requiredCount,
                                color: const Color(0xFF69F0AE),
                                backgroundColor: Colors.white12,
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Postęp: $currentMissionKills / ${allMissionsPool[activeMissionIndex!].requiredCount}', style: const TextStyle(fontSize: 11)),
                            const SizedBox(height: 8),
                            if (currentMissionKills >= allMissionsPool[activeMissionIndex!].requiredCount)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), minimumSize: const Size(double.infinity, 32)),
                                onPressed: () {
                                  final m = allMissionsPool[activeMissionIndex!];
                                  setState(() {
                                    if (m.type == MissionType.itemSupply) {
                                      craftingBag[m.supplyItemId!] = (craftingBag[m.supplyItemId!] ?? 0) - m.requiredCount;
                                    }
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
                                child: const Text('Odbierz Nagrodę! 🎁', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                                child: const Text('Porzuć misję', style: TextStyle(color: Color(0xFFFF5252), fontSize: 11)),
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
                              child: Text('${loc.icon} ${loc.name}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF80D8FF))),
                            ),
                            ...locMissions.map((m) {
                              final bool isUnlocked = passedRankIndex >= m.minRankIndex;

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 3),
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isUnlocked ? const Color(0xFFE65100) : const Color(0xFF263238),
                                    child: Text(m.rank, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: isUnlocked ? Colors.white : Colors.white38)),
                                  ),
                                  title: Text(m.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isUnlocked ? Colors.white : Colors.white38)),
                                  subtitle: Text('${m.desc}\nNagroda: ${m.rewardRyo} Ryo | +${m.rewardExp} EXP', style: const TextStyle(fontSize: 10, color: Colors.white60)),
                                  trailing: isUnlocked
                                      ? ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFE65100),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              activeMissionIndex = allMissionsPool.indexOf(m);
                                              if (m.type == MissionType.itemSupply) {
                                                final held = craftingBag[m.supplyItemId] ?? 0;
                                                currentMissionKills = min(held, m.requiredCount);
                                              } else {
                                                currentMissionKills = 0;
                                              }
                                            });
                                            _saveGameData();
                                            Navigator.pop(ctx);
                                            addLog('📜 Przyjęto zlecenie: ${m.title}!');
                                          },
                                          child: const Text('Przyjmij', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.lock, size: 18, color: Colors.grey),
                                          onPressed: () => showActionBlockedMessage('🚫 Wymagana wyższa ranga ninja na tę misję!'),
                                        ),
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
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zamknij', style: TextStyle(color: Colors.grey)))],
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
            title: const Text('📜 Zwoje Technik (Max 3 aktywne)', style: TextStyle(color: Color(0xFF80D8FF), fontSize: 16, fontWeight: FontWeight.bold)),
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
                    title: Text(jutsu.name, style: TextStyle(fontSize: 13, color: jutsu.color, fontWeight: FontWeight.bold)),
                    subtitle: Text('Koszt: ${jutsu.chakraCost} CP | Siła: x${jutsu.powerMultiplier}\n${jutsu.effectDescription}', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                    trailing: isKnown
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEquipped ? const Color(0xFF2E7D32) : const Color(0xFF37474F),
                            ),
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
                            child: Text(isEquipped ? 'Założone' : 'Załóż', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
                            onPressed: () {
                              if (ryo < jutsu.costRyo) {
                                showActionBlockedMessage('💰 Brakuje Ci ${jutsu.costRyo - ryo} Ryo!');
                                return;
                              }
                              setState(() {
                                ryo -= jutsu.costRyo;
                                knownJutsu.add(jutsu);
                              });
                              _saveGameData();
                              setScrollsState(() {});
                              addLog('📜 Nauczono się techniki: ${jutsu.name}!');
                            },
                            child: Text('Kup (${jutsu.costRyo})', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                  );
                },
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zamknij', style: TextStyle(color: Colors.grey)))],
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
            title: const Text('🎒 Prowiant i Surowce', style: TextStyle(color: Color(0xFFFFB74D), fontSize: 17, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Posiadany prowiant i mikstury:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70)),
                    const SizedBox(height: 4),
                    if (bag.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Brak przedmiotów w plecaku!', style: TextStyle(fontSize: 12, color: Colors.white54)),
                      )
                    else
                      ...bag.entries.map((entry) {
                        final item = allConsumables.firstWhere((c) => c.id == entry.key);
                        final qty = entry.value;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFF141211), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                          child: Row(
                            children: [
                              Text(item.icon, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${item.name} (x$qty)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text(item.description, style: const TextStyle(fontSize: 10, color: Colors.white60)),
                                    const SizedBox(height: 2),
                                    Text(item.statBonusText, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFFD54F))),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00695C), padding: const EdgeInsets.symmetric(horizontal: 10)),
                                onPressed: () {
                                  useConsumable(item);
                                  setBagState(() {});
                                },
                                child: const Text('Użyj', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      }),
                    const Divider(color: Colors.white12),
                    const Text('Materiały rzemieślnicze:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFFFD54F))),
                    ...craftingMaterials.values.map((mat) {
                      final count = craftingBag[mat.id] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${mat.icon} ${mat.name}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                            Text('$count szt.', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFFD54F))),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zamknij', style: TextStyle(color: Colors.grey)))],
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
                Expanded(child: Text('Legendarne Lochy', style: TextStyle(color: Color(0xFFCE93D8), fontWeight: FontWeight.bold))),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Posiadane klucze: 🗝️ $keysCount szt.', style: const TextStyle(fontSize: 12, color: Color(0xFFFFD54F), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    if (inCooldown)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.red.withAlpha(40), borderRadius: BorderRadius.circular(6)),
                        child: Text('⏳ Odnowienie lochów: ${remainingCooldownSec ~/ 60}m ${remainingCooldownSec % 60}s', style: const TextStyle(fontSize: 11, color: Color(0xFFFF5252))),
                      ),
                    const Divider(color: Colors.white12),
                    ...dungeonBossesPool.map((boss) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(10),
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
                                Text('${boss.icon} ${boss.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFF3E5F5))),
                                Text('Lvl ${boss.minLevel}+', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            Text('${boss.title} (Unikalny Set Bossa)', style: const TextStyle(fontSize: 10, color: Color(0xFFFF8A80))),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B1FA2)),
                                onPressed: () {
                                  if (level < boss.minLevel) {
                                    showActionBlockedMessage('🚫 Wymagany poziom ${boss.minLevel} do tej walki!');
                                    return;
                                  }
                                  if (keysCount <= 0) {
                                    showActionBlockedMessage('🗝️ Brak Klucza do Lochów!');
                                    return;
                                  }
                                  if (inCooldown) {
                                    showActionBlockedMessage('⏳ Loch w trakcie odnowienia!');
                                    return;
                                  }
                                  setState(() {
                                    craftingBag[matDungeonKey] = keysCount - 1;
                                    dungeonCooldownTimestamp = DateTime.now().millisecondsSinceEpoch + (3 * 60 * 1000);
                                  });
                                  _saveGameData();
                                  Navigator.pop(ctx);
                                  _startBattleWithEnemy(
                                    EnemyTemplate(id: boss.id, name: boss.name, title: boss.title, baseHp: boss.baseHp, baseAtk: boss.baseAtk, locationId: '', isBoss: true, icon: boss.icon, critRate: 15, armorPierce: 15),
                                    dungeonBossSetGroup: boss.setGroup,
                                  );
                                },
                                child: const Text('Wejdź do Lochu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zamknij', style: TextStyle(color: Colors.grey)))],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFFF8A65))));
    }

    final activeLocation = shinobiLocations.firstWhere((l) => l.id == currentSelectedLocationId);

    return Scaffold(
      backgroundColor: const Color(0xFF0C0807),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF140D0B),
              border: Border.symmetric(vertical: BorderSide(color: Color(0xFF2E1911), width: 1.5)),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(inVillage ? 'Konohagakure (Baza)' : activeLocation.name),
                centerTitle: true,
                backgroundColor: const Color(0xFF1A100B),
                elevation: 0,
                leading: IconButton(
                  icon: const Text('🏠', style: TextStyle(fontSize: 20)),
                  tooltip: 'Menu Startowe',
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const StartMenuScreen()),
                    );
                  },
                ),
              ),
              body: Column(
                children: [
                  _buildTopHeroPanel(),
                  Expanded(
                    child: inVillage ? _buildVillageView() : _buildExplorationView(activeLocation),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeroPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1310),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3E2723), width: 1.4),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    Row(
                      children: [
                        _itemCardExpanded('Broń', currentWeapon, 'Atak: +$totalAttack'),
                        const SizedBox(width: 5),
                        _itemCardExpanded('Pancerz', currentArmor, 'Obr: +${currentArmor.effectiveStat}'),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _itemCardExpanded('Głowa', currentHelmet, 'Obr: +${currentHelmet.effectiveStat}'),
                        const SizedBox(width: 5),
                        _itemCardExpanded('Buty', currentBoots, 'Obr: +${currentBoots.effectiveStat}'),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _itemCardExpanded('Talizman', currentTrinket, 'Moc: +${currentTrinket.effectiveStat}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: InkWell(
                  onTap: _showStatsDialog,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF140E0C),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Profil Ninja (ℹ️):', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text('Lvl $level', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: rankColor)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(ninjaRank, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: rankColor)),
                        const Divider(color: Colors.white12, height: 10),
                        _statRowMini('EXP', '$ninjaExp / $expForNextLevel', const Color(0xFF80D8FF)),
                        _statRowMini('HP', '$hp/$maxHp', const Color(0xFF69F0AE)),
                        _statRowMini('CP', '$chakra/$maxChakra', const Color(0xFF40C4FF)),
                        _statRowMini('Ryo', '$ryo', const Color(0xFFFFD54F)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Kafelek plecaka wpasowany dokładnie w zaznaczone miejsce pod talizmanem
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openEquipmentStashDialog,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF140D0A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFB74D).withAlpha(120), width: 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text('📦', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 6),
                        Text('Plecak Rynsztunku', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D))),
                      ],
                    ),
                    Text('${equipmentStash.length} / 10 slotów', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: equipmentStash.length >= 10 ? const Color(0xFFFF5252) : const Color(0xFF69F0AE))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVillageView() {
    final totalItemsInBag = bag.values.fold(0, (a, b) => a + b);

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _openLocationSelectionModal,
              icon: const Text('🌲', style: TextStyle(fontSize: 22)),
              label: const Text('Wyrusz w Las (Wybierz Strefę)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.45,
              children: [
                _villageHubCard(
                  title: 'Biuro Misji',
                  subtitle: activeMissionIndex != null ? 'Aktywna misja!' : 'Egzaminy i zlecenia',
                  icon: '📜',
                  color: const Color(0xFF5D4037),
                  onTap: _openVillageMissionsDialog,
                ),
                _villageHubCard(
                  title: 'Prowiant i Zapas',
                  subtitle: '$totalItemsInBag mikstur i zasobów',
                  icon: '🎒',
                  color: const Color(0xFF00695C),
                  onTap: _openBagDialog,
                ),
                _villageHubCard(
                  title: 'Zwoje Jutsu',
                  subtitle: '${equippedJutsu.length}/3 aktywnych technik',
                  icon: '🌀',
                  color: const Color(0xFF1565C0),
                  onTap: _openScrollsDialog,
                ),
                _villageHubCard(
                  title: 'Lochy Wioski',
                  subtitle: 'Legendarne Bossy',
                  icon: '🏛️',
                  color: const Color(0xFF7B1FA2),
                  onTap: _openDungeonsDialog,
                ),
                _villageHubCard(
                  title: 'Zbrojmistrz',
                  subtitle: 'Ulepszanie rynsztunku',
                  icon: '🔨',
                  color: const Color(0xFFBF360C),
                  onTap: _openBlacksmithDialog,
                ),
                _villageHubCard(
                  title: 'Szpital Konohy',
                  subtitle: 'Medyk i witalność',
                  icon: '🩺',
                  color: const Color(0xFF1B5E20),
                  onTap: _openMedicDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _villageHubCard({required String title, required String subtitle, required String icon, required Color color, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(140), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplorationView(ShinobiLocation loc) {
    final activeMission = activeMissionIndex != null ? allMissionsPool[activeMissionIndex!] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A1711), Color(0xFF160D0A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE65100).withAlpha(120), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(loc.icon, style: const TextStyle(fontSize: 30)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D))),
                          const SizedBox(height: 2),
                          Text(loc.description, style: const TextStyle(fontSize: 11, color: Colors.white60), maxLines: 2),
                        ],
                      ),
                    ),
                  ],
                ),
                if (activeMission != null && activeMission.locationId == loc.id) ...[
                  const Divider(color: Colors.white12, height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🎯 Misja: ${activeMission.title}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF80D8FF))),
                      Text('$currentMissionKills / ${activeMission.requiredCount}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF69F0AE))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: currentMissionKills / activeMission.requiredCount,
                      backgroundColor: Colors.white10,
                      color: const Color(0xFF69F0AE),
                      minHeight: 6,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Spacer(),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text('📜 Dziennik Zdarzeń (3 ost.):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white60)),
          ),
          const SizedBox(height: 4),
          Container(
            height: 64,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF100C0A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: log.take(3).length,
              itemBuilder: (context, index) {
                final entry = log[index];
                final isFirst = index == 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.0),
                  child: Text(
                    entry,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: isFirst ? 11 : 10,
                      fontWeight: isFirst ? FontWeight.bold : FontWeight.normal,
                      color: isFirst ? const Color(0xFFFFCC80) : Colors.white60,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00695C),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _openBagDialog,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('🎒 Prowiant', softWrap: false, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: proceedExploration,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Idź naprzód 🌲', softWrap: false, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: returnToVillage,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Powrót', softWrap: false, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _statRowMini(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _itemCardExpanded(String slot, NinjaGear item, String statText) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showItemDetailsDialog(slot, item),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF140D0A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: item.borderColor, width: item.borderWidth),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(item.icon, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(slot, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: item.borderColor)),
                          ),
                        ],
                      ),
                    ),
                    if (item.isBossSet)
                      const Text('🔥', style: TextStyle(fontSize: 8))
                    else if (item.isSoulbound)
                      const Text('📜', style: TextStyle(fontSize: 8)),
                  ],
                ),
                const SizedBox(height: 1),
                Text(item.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: item.borderColor)),
                Text(statText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
