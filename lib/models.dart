enum GearSlot {
  weapon,
  helmet,
  armor,
  boots,
  trinket,
}

enum ItemRarity {
  common,
  rare,
  epic,
  legendary,
}

enum BossTrait {
  chakraLeech,
  ironSkin,
  poisonMaster,
  dodgeManiac,
  bloodEnrage,
  chakraThorns,
}

enum JutsuRank {
  academy,
  genin,
  chunin,
  jonin,
  sannin,
}

enum JutsuType {
  damage,
  heal,
  shield,
  stun,
}

class Jutsu {
  final String id;
  final String name;
  final JutsuRank rank;
  final JutsuType type;
  final int chakraCost;
  final double powerMultiplier;
  final String description;
  final int value;

  const Jutsu({
    required this.id,
    required this.name,
    required this.rank,
    required this.type,
    required this.chakraCost,
    required this.powerMultiplier,
    required this.description,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rank': rank.index,
        'type': type.index,
        'chakraCost': chakraCost,
        'powerMultiplier': powerMultiplier,
        'description': description,
        'value': value,
      };

  factory Jutsu.fromJson(Map<String, dynamic> json) => Jutsu(
        id: json['id'] as String,
        name: json['name'] as String,
        rank: JutsuRank.values[json['rank'] as int],
        type: JutsuType.values[json['type'] as int],
        chakraCost: json['chakraCost'] as int,
        powerMultiplier: (json['powerMultiplier'] as num).toDouble(),
        description: json['description'] as String,
        value: json['value'] as int,
      );
}

class EquipmentItem {
  final String id;
  final String name;
  final GearSlot slot;
  final ItemRarity rarity;
  final int baseStat;
  final int upgradeLevel;
  final String? setGroup;
  final String? specialEffect;
  final int price;

  const EquipmentItem({
    required this.id,
    required this.name,
    required this.slot,
    required this.rarity,
    required this.baseStat,
    this.upgradeLevel = 0,
    this.setGroup,
    this.specialEffect,
    this.price = 100,
  });

  int get effectiveStat => baseStat + (upgradeLevel * (rarity.index + 1) * 2);

  EquipmentItem copyWith({
    String? id,
    String? name,
    GearSlot? slot,
    ItemRarity? rarity,
    int? baseStat,
    int? upgradeLevel,
    String? setGroup,
    String? specialEffect,
    int? price,
  }) {
    return EquipmentItem(
      id: id ?? this.id,
      name: name ?? this.name,
      slot: slot ?? this.slot,
      rarity: rarity ?? this.rarity,
      baseStat: baseStat ?? this.baseStat,
      upgradeLevel: upgradeLevel ?? this.upgradeLevel,
      setGroup: setGroup ?? this.setGroup,
      specialEffect: specialEffect ?? this.specialEffect,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slot': slot.index,
        'rarity': rarity.index,
        'baseStat': baseStat,
        'upgradeLevel': upgradeLevel,
        'setGroup': setGroup,
        'specialEffect': specialEffect,
        'price': price,
      };

  factory EquipmentItem.fromJson(Map<String, dynamic> json) => EquipmentItem(
        id: json['id'] as String,
        name: json['name'] as String,
        slot: GearSlot.values[json['slot'] as int],
        rarity: ItemRarity.values[json['rarity'] as int],
        baseStat: json['baseStat'] as int,
        upgradeLevel: json['upgradeLevel'] as int? ?? 0,
        setGroup: json['setGroup'] as String?,
        specialEffect: json['specialEffect'] as String?,
        price: json['price'] as int? ?? 100,
      );
}

class EnemyTemplate {
  final String id;
  final String name;
  final int maxHp;
  final int baseAtk;
  final int baseDef;
  final int critRate;
  final int dodgeRate;
  final int pierceRate;
  final List<BossTrait> traits;
  final bool isBoss;

  const EnemyTemplate({
    required this.id,
    required this.name,
    required this.maxHp,
    required this.baseAtk,
    this.baseDef = 10,
    this.critRate = 5,
    this.dodgeRate = 5,
    this.pierceRate = 5,
    this.traits = const [],
    this.isBoss = false,
  });
}

class BingoTarget {
  final String id;
  final String name;
  final String title;
  final String zoneId;
  final int minDepth;
  final EnemyTemplate enemy;
  final EquipmentItem exclusiveReward;
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
