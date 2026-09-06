import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

void main() => runApp(const ShinobiLooterApp());

const NinjaGear defaultStarterWeapon = NinjaGear(name: 'Podstawowy Kunai', rarity: ItemRarity.common, slot: GearSlot.weapon, baseStat: 5, isSoulbound: true, icon: '🗡️');
const NinjaGear defaultStarterArmor = NinjaGear(name: 'Szata Treningowa Genina', rarity: ItemRarity.common, slot: GearSlot.armor, baseStat: 4, isSoulbound: true, icon: '🥋');
const NinjaGear defaultStarterHelmet = NinjaGear(name: 'Ochraniacz Protektor', rarity: ItemRarity.common, slot: GearSlot.helmet, baseStat: 3, isSoulbound: true, icon: '🛡️');
const NinjaGear defaultStarterBoots = NinjaGear(name: 'Sandały Shinobi', rarity: ItemRarity.common, slot: GearSlot.boots, baseStat: 3, isSoulbound: true, icon: '🥾');
const NinjaGear defaultStarterTrinket = NinjaGear(name: 'Amulet Konohy', rarity: ItemRarity.common, slot: GearSlot.trinket, baseStat: 3, isSoulbound: true, icon: '📿');

void showHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1B1411),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFFB74D), width: 1.2),
      ),
      title: const Row(
        children: [
          Text('📖 ', style: TextStyle(fontSize: 22)),
          Expanded(
            child: Text(
              'Przewodnik Młodego Shinobi',
              style: TextStyle(color: Color(0xFFFFB74D), fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _helpSection('⛩️ Cel Gry', 'Eksploruj strefy, zbieraj surowce, ulepszaj rynsztunek i zdawaj egzaminy ninja na wyższe rangi.'),
              const Divider(color: Colors.white12),
              _helpSection('📜 Zwój Powrotu (Extraction)', 'Podczas rajdu nie możesz wrócić w dowolnym momencie. Szukaj rzadkiego Zwoju Powrotu, aby bezpiecznie ewakuować się do Wioski z całym łupem.'),
              const Divider(color: Colors.white12),
              _helpSection('💀 Śmierć i Pieczęcie (Fūinjutsu)', 'Porażka w walce oznacza utratę plecaka i całego niezabezpieczonego sprzętu. Szukaj Mistrza Fūinjutsu w terenie, by na stałe zapieczętować cenne przedmioty.'),
              const Divider(color: Colors.white12),
              _helpSection('⚔️ Walka i Rynsztunek', 'Gotowy rynsztunek wypada wyłącznie z pokonanych wrogów. Podczas eksploracji znajdziesz tylko surowce kowalskie i prowiant.'),
              const Divider(color: Colors.white12),
              _helpSection('🔨 Wioska Konoha', 'U Kowala ulepszysz rynsztunek surowcami, w Szpitalu wyleczysz rany i zwiększysz bazową witalność, a w Biurze Misji podejmiesz zlecenia oraz egzaminy na rangi.'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Rozumiem!', style: TextStyle(color: Color(0xFFFFB74D), fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

Widget _helpSection(String title, String desc) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFCC80))),
        const SizedBox(height: 2),
        Text(desc, style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.3)),
      ],
    ),
  );
}

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
                    const SizedBox(height: 14),
                    TextButton.icon(
                      onPressed: () => showHelpDialog(context),
                      icon: const Icon(Icons.help_outline, color: Colors.white60, size: 18),
                      label: const Text('Jak grać? (Poradnik)', style: TextStyle(color: Colors.white60, fontSize: 13)),
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

  bool hasEscapeScroll = false;

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
      hasEscapeScroll = prefs.getBool('hasEscapeScroll') ?? false;

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
    await prefs.setBool('hasEscapeScroll', hasEscapeScroll);

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
      hasEscapeScroll = false;

      if (fallenInBattle) {
        if (!currentWeapon.isSoulbound) currentWeapon = defaultStarterWeapon;
        if (!currentArmor.isSoulbound) currentArmor = defaultStarterArmor;
        if (!currentHelmet.isSoulbound) currentHelmet = defaultStarterHelmet;
        if (!currentBoots.isSoulbound) currentBoots = defaultStarterBoots;
        if (!currentTrinket.isSoulbound) currentTrinket = defaultStarterTrinket;
        equipmentStash.clear();
        bag.clear();
      }
    });

    if (fallenInBattle) {
      addLog('💀 Porażka w terenie! Utracono rynsztunek i plecak bez pieczęci.');
    } else {
      addLog('⛩️ Bezpieczna ewakuacja Zwojem Powrotu do Konohy.');
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
      hasEscapeScroll = false;
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

    if (roll < 20) {
      const emptyMessages = [
        '🌿 Spokojna okolica. Wokół panuje cisza.',
        '🍃 Wędrówka mija bez echa, wiatr szumi w koronach.',
        '🌳 Cisza i spokój. Łapiesz krótki oddech.',
        '🌲 Pusta ścieżka, patrolujesz teren bez zakłóceń.'
      ];
      addLog(emptyMessages[_rng.nextInt(emptyMessages.length)]);
    } else if (roll < 38) {
      final subRoll = _rng.nextInt(100);
      if (subRoll < 50) {
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
    } else if (!hasEscapeScroll && roll < 43) {
      setState(() => hasEscapeScroll = true);
      addLog('📜 ODKRYCIE! Znaleziono Zwój Powrotu! Możesz bezpiecznie ewakuować się do Konohy.');
      _saveGameData();
    } else if (roll < 46) {
      _encounterWanderingMerchant();
    } else if (roll < 88) {
      final locationEnemies = standardEnemiesPool.where((e) => e.locationId == currentSelectedLocationId).toList();
      final enemy = locationEnemies.isNotEmpty ? locationEnemies[_rng.nextInt(locationEnemies.length)] : standardEnemiesPool[0];

      final pRoll = _rng.nextInt(100);
      EnemyPrefix p = pRoll < 60 ? EnemyPrefix.weak : (pRoll < 88 ? EnemyPrefix.normal : EnemyPrefix.strong);
      _startBattleWithEnemy(enemy, forcePrefix: p);
    } else if (roll < 92) {
      final locationBosses = bossesPool.where((b) => b.locationId == currentSelectedLocationId).toList();
      if (locationBosses.isNotEmpty) {
        final boss = locationBosses[_rng.nextInt(locationBosses.length)];
        addLog('⚠️ ${loc.name}: Pojawił się boss -> ${boss.name}!');
        _startBattleWithEnemy(boss);
      } else {
        final locationEnemies = standardEnemiesPool.where((e) => e.locationId == currentSelectedLocationId).toList();
        final enemy = locationEnemies.isNotEmpty ? locationEnemies[_rng.nextInt(locationEnemies.length)] : standardEnemiesPool[0];
        _startBattleWithEnemy(enemy, forcePrefix: EnemyPrefix.strong);
      }
    } else if (roll < 96) {
      _encounterSealMaster();
    } else {
      _encounterWanderingSage();
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
            title: Row(
              children: [
                const Text('🛒 ', style: TextStyle(fontSize: 22)),
                const Expanded(child: Text('Wędrowny Skup Rynsztunku', style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 15))),
                Text('💰 $ryo Ryo', style: const TextStyle(fontSize: 12, color: Color(0xFFFFD54F), fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('„Witaj wędrowcze! Skupuję rzadki sprzęt z Twojego plecaka po okazyjnej cenie (45% wartości rynkowej).”', style: TextStyle(fontSize: 11, color: Colors.white70, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 14),
                    if (equipmentStash.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text('Twój plecak rynsztunku jest pusty. Nie masz nic na sprzedaż.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      )
                    else
                      ...equipmentStash.toList().map((gear) {
                        final premiumPrice = gear.merchantSellPrice;
                        String slotName = gear.slot == GearSlot.weapon ? 'Broń' : (gear.slot == GearSlot.armor ? 'Pancerz' : (gear.slot == GearSlot.helmet ? 'Głowa' : (gear.slot == GearSlot.boots ? 'Buty' : 'Talizman')));

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141211),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: gear.borderColor, width: 1.0),
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
                                    Text('Oferta skupu: $premiumPrice Ryo', style: const TextStyle(fontSize: 10, color: Color(0xFFFFD54F))),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00695C), 
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                                ),
                                onPressed: () {
                                  setState(() {
                                    ryo += premiumPrice;
                                    equipmentStash.remove(gear);
                                  });
                                  _saveGameData();
                                  setMerchantState(() {});
                                  addLog('🛒 Sprzedano kupcowi [${gear.displayName}] za +$premiumPrice Ryo.');
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
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Odejdź', style: TextStyle(color: Colors.grey)))],
          );
        },
      ),
    );
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
        title: Row(
          children: [
            const Text('🈴 ', style: TextStyle(fontSize: 22)),
            const Expanded(child: Text('Mistrz Fūinjutsu', style: TextStyle(color: Color(0xFFFF8A80), fontWeight: FontWeight.bold, fontSize: 15))),
            Text('💰 $ryo Ryo', style: const TextStyle(fontSize: 12, color: Color(0xFFFFD54F), fontWeight: FontWeight.bold)),
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
        title: Row(
          children: [
            const Text('👴🏻 ', style: TextStyle(fontSize: 22)),
            const Expanded(child: Text('Wędrowny Mędrzec', style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 15))),
            Text('💰 $ryo Ryo', style: const TextStyle(fontSize: 12, color: Color(0xFFFFD54F), fontWeight: FontWeight.bold)),
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
          final int healCost = 25 + (level * 5);
          final int vitalCost = (250 * pow(1.4, vitalTrainingCount)).floor();

          return AlertDialog(
            backgroundColor: const Color(0xFF102018),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF66BB6A), width: 1.2)),
            title: Row(
              children: [
                const Text('🩺 ', style: TextStyle(fontSize: 22)),
                const Expanded(child: Text('Szpital Konohy (Medyk)', style: TextStyle(color: Color(0xFFA5D6A7), fontWeight: FontWeight.bold))),
                Text('💰 $ryo Ryo', style: const TextStyle(fontSize: 12, color: Color(0xFFFFD54F), fontWeight: FontWeight.bold)),
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
                      subtitle: const Text('+10 Max HP i +10 Max CP (Baza)', style: const TextStyle(fontSize: 11, color: Colors.white60)),
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
            title: Row(
              children: [
                const Text('🔨 ', style: TextStyle(fontSize: 22)),
                const Expanded(child: Text('Zbrojmistrz Konohy (Kowal)', style: TextStyle(color: Color(0xFFFFAB91), fontWeight: FontWeight.bold))),
                Text('💰 $ryo Ryo', style: const TextStyle(fontSize: 12, color: Color(0xFFFFD54F), fontWeight: FontWeight.bold)),
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
                      int ryoCost = (60 * pow(1 + curLvl, 1.5) + (gear.rarity.index * 45)).round();

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
                                      int successRate = curLvl < 3 ? 90 : (curLvl < 6 ? 70 : 50);
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
                Expanded(child: Text('Plecak Ekwipunku (${equipmentStash.length}/10)', style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 15, fontWeight: FontWeight.bold))),
                Text('💰 $ryo Ryo', style: const TextStyle(fontSize: 12, color: Color(0xFFFFD54F), fontWeight: FontWeight.bold)),
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
                                    Text('Moc: +${gear.effectiveStat} | Złom: ${gear.sellPrice} Ryo', style: const TextStyle(fontSize: 9, color: Colors.white70)),
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
                                  addLog('💰 Zezłomowano z plecaka [${gear.displayName}] za +$price Ryo.');
                                },
                                child: const Text('Złomuj', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
            title: Row(
              children: [
                const Expanded(child: Text('📜 Biuro Misji i Egzaminów', style: TextStyle(color: Color(0xFFFFB74D), fontWeight: FontWeight.bold, fontSize: 16))),
                Text('💰 $ryo Ryo', style: const TextStyle(fontSize: 12, color: Color(0xFFFFD54F), fontWeight: FontWeight.bold)),
              ],
            ),
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
                                  final bool isRepeat = completedMissionsHistory.contains(m.id);
                                  final int payoutRyo = isRepeat ? max(10, (m.rewardRyo * 0.40).round()) : m.rewardRyo;
                                  final int payoutExp = isRepeat ? max(10, (m.rewardExp * 0.40).round()) : m.rewardExp;

                                  setState(() {
                                    if (m.type == MissionType.itemSupply) {
                                      craftingBag[m.supplyItemId!] = (craftingBag[m.supplyItemId!] ?? 0) - m.requiredCount;
                                    }
                                    ryo += payoutRyo;
                                    completedMissionsHistory.add(m.id);
                                    activeMissionIndex = null;
                                    currentMissionKills = 0;
                                  });
                                  addExperience(payoutExp);
                                  _saveGameData();
                                  Navigator.pop(ctx);
                                  addLog('🎖️ Ukończono: ${m.title}! +$payoutRyo Ryo, +$payoutExp EXP ${isRepeat ? "(Powtórzenie)" : ""}');
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
                              final bool isCompleted = completedMissionsHistory.contains(m.id);
                              final int displayRyo = isCompleted ? (m.rewardRyo * 0.4).round() : m.rewardRyo;
                              final int displayExp = isCompleted ? (m.rewardExp * 0.4).round() : m.rewardExp;

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
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(m.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isUnlocked ? Colors.white : Colors.white38)),
                                      ),
                                      if (isCompleted)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(color: Colors.blueGrey.withAlpha(80), borderRadius: BorderRadius.circular(4)),
                                          child: const Text('Powtórka -60%', style: TextStyle(fontSize: 9, color: Color(0xFF80D8FF))),
                                        ),
                                    ],
                                  ),
                                  subtitle: Text('${m.desc}\nNagroda: $displayRyo Ryo | +$displayExp EXP', style: const TextStyle(fontSize: 10, color: Colors.white60)),
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
            title: Row(
              children: [
                const Expanded(child: Text('📜 Zwoje Technik (Max 3 aktywne)', style: TextStyle(color: Color(0xFF80D8FF), fontSize: 14, fontWeight: FontWeight.bold))),
                Text('💰 $ryo Ryo', style: const TextStyle(fontSize: 12, color: Color(0xFFFFD54F), fontWeight: FontWeight.bold)),
              ],
            ),
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
            title: Row(
              children: [
                const Expanded(child: Text('🎒 Prowiant i Surowce', style: TextStyle(color: Color(0xFFFFB74D), fontSize: 16, fontWeight: FontWeight.bold))),
                Text('💰 $ryo Ryo', style: const TextStyle(fontSize: 12, color: Color(0xFFFFD54F), fontWeight: FontWeight.bold)),
              ],
            ),
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
            title: Row(
              children: [
                const Text('🏛️ ', style: TextStyle(fontSize: 22)),
                const Expanded(child: Text('Legendarne Lochy', style: TextStyle(color: Color(0xFFCE93D8), fontWeight: FontWeight.bold))),
                Text('💰 $ryo Ryo', style: const TextStyle(fontSize: 12, color: Color(0xFFFFD54F), fontWeight: FontWeight.bold)),
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

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF191311),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFFFB74D), width: 1.2)),
        title: Row(
          children: [
            const Text('🥋 ', style: TextStyle(fontSize: 22)),
            Expanded(child: Text('Statystyki ($ninjaRank)', style: TextStyle(color: rankColor, fontSize: 15, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statPopupRow('Poziom Ninja', '$level (EXP: $ninjaExp / $expForNextLevel)', const Color(0xFF80D8FF)),
              _statPopupRow('Punkty Życia (HP)', '$hp / $maxHp (Baza: $baseMaxHp, Rynsztunek: +${sumAffix(AffixType.bonusHp)})', const Color(0xFF69F0AE)),
              _statPopupRow('Czakra (CP)', '$chakra / $maxChakra (Baza: $baseMaxChakra, Rynsztunek: +${sumAffix(AffixType.bonusChakra)})', const Color(0xFF40C4FF)),
              const Divider(color: Colors.white12),
              _statPopupRow('Łączny Atak', '$totalAttack (Rynsztunek + Poziom)', const Color(0xFFFF8A65)),
              _statPopupRow('Łączna Obrona', '$totalDefense', const Color(0xFFB0BEC5)),
              _statPopupRow('Szansa na Krytyk', '$totalCritRate%', const Color(0xFFFF5252)),
              _statPopupRow('Unik (Kawarimi)', '$totalDodgeRate%', const Color(0xFFFFD54F)),
              _statPopupRow('Przebicie Pancerza', '$totalArmorPierce%', const Color(0xFFBA68C8)),
              _statPopupRow('Kradzież Życia (Lifesteal)', '$totalLifeSteal%', const Color(0xFFE91E63)),
              _statPopupRow('Regeneracja HP/turę', '+$totalHpRegen HP', const Color(0xFF81C784)),
              _statPopupRow('Regeneracja CP/turę', '+$totalChakraRegen CP', const Color(0xFF4FC3F7)),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zamknij', style: TextStyle(color: Colors.grey)))],
      ),
    );
  }

  Widget _statPopupRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  void _startBattleWithEnemy(EnemyTemplate template, {EnemyPrefix forcePrefix = EnemyPrefix.normal, bool isExamFight = false, int? examTargetRank, String? dungeonBossSetGroup}) {
    double hpMult = 1.0;
    double atkMult = 1.0;
    String prefixTitle = '';
    Color prefixColor = const Color(0xFFFFA726);

    int enemyCrit = template.critRate;
    int enemyDodge = template.dodgeRate;
    int enemyPierce = template.armorPierce;
    int enemyBlock = template.flatBlock;

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
          enemyCrit += 8;
          enemyDodge += 5;
          enemyPierce += 10;
          enemyBlock += 3;
          break;
      }
    }

    int scaledHp = template.baseHp;
    int scaledAtk = template.baseAtk;

    if (isExamFight) {
      int minExamHp = (totalAttack * 4).round();
      scaledHp = max(template.baseHp + (level * 28), minExamHp);
      scaledAtk = max(template.baseAtk + (level * 2), (totalDefense * 0.7).round() + 6);
    } else if (template.isBoss) {
      scaledHp = (template.baseHp * (1.0 + (level * 0.08))).round();
      scaledAtk = (template.baseAtk * (1.0 + (level * 0.05))).round();
    } else {
      scaledHp = (template.baseHp * (1.0 + (level * 0.06))).round();
      scaledAtk = (template.baseAtk * (1.0 + (level * 0.04))).round();
    }

    final int enemyMaxHp = (scaledHp * hpMult).round();
    final int enemyBaseAtk = (scaledAtk * atkMult).round();
    int enemyHp = enemyMaxHp;

    String initialMsg = isExamFight ? '🥋 EGZAMIN: Egzaminator ${template.name} atakuje!' : (template.isBoss ? '⚠️ BOSS: Pojawia się ${template.name}!' : 'Z cienia atakuje $prefixTitle${template.name}!');
    List<String> battleLogHistory = [initialMsg];
    int frozenTurns = 0;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0xFF141211),
      shape: const RoundedRectangleBorder(borderRadius: vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setBattleState) {
            void appendBattleLog(String line) {
              battleLogHistory.insert(0, line);
              if (battleLogHistory.length > 8) battleLogHistory.removeLast();
            }

            void applyTurnRegen() {
              if (totalHpRegen > 0) {
                setState(() => hp = min(maxHp, hp + totalHpRegen));
                appendBattleLog('💚 Regeneracja: +$totalHpRegen HP.');
              }
              if (totalChakraRegen > 0) {
                setState(() => chakra = min(maxChakra, chakra + totalChakraRegen));
                appendBattleLog('🌀 Regeneracja: +$totalChakraRegen CP.');
              }
            }

            void enemyTurn() {
              if (enemyHp <= 0) return;
              if (frozenTurns > 0) {
                frozenTurns--;
                appendBattleLog('❄️ ${template.name} jest unieruchomiony!');
                applyTurnRegen();
                setBattleState(() {});
                return;
              }

              if (_rng.nextInt(100) < totalDodgeRate) {
                appendBattleLog('🪵 Kawarimi! Uniknąłeś ataku dzięki podmianie z kłodą!');
                applyTurnRegen();
                setBattleState(() {});
                return;
              }

              bool isEnemyCrit = _rng.nextInt(100) < enemyCrit;
              double eCritMult = isEnemyCrit ? 1.5 : 1.0;

              int effectivePlayerDef = (totalDefense * (100 - enemyPierce) / 100).round();
              final rawDmg = ((enemyBaseAtk + _rng.nextInt(4)) * eCritMult).round();
              final dmg = max(2, rawDmg - (effectivePlayerDef ~/ 2));

              setState(() {
                hp = max(0, hp - dmg);
              });

              if (isEnemyCrit) {
                appendBattleLog('💥 KRYTYK WROGA! ${template.name} zadaje $dmg obrażeń!');
              } else {
                appendBattleLog('${template.name} zadaje Ci $dmg obrażeń.');
              }

              applyTurnRegen();
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

              if (_rng.nextInt(100) < enemyDodge) {
                appendBattleLog('🪵 Wróg wykonał Kawarimi i uniknął ciosu!');
                enemyTurn();
                setBattleState(() {});
                return;
              }

              bool isPlayerCrit = _rng.nextInt(100) < totalCritRate;
              double pCritMult = isPlayerCrit ? 1.5 : 1.0;

              final dealt = ((((totalAttack * jutsu.powerMultiplier) + _rng.nextInt(4)) * pCritMult).round() - enemyBlock);
              final finalDealt = max(2, dealt);

              enemyHp = max(0, enemyHp - finalDealt);

              if (totalLifeSteal > 0) {
                int healed = max(1, (finalDealt * totalLifeSteal / 100).round());
                setState(() => hp = min(maxHp, hp + healed));
                appendBattleLog('🩸 Lifesteal: Odzyskano $healed HP!');
              }

              if (isPlayerCrit) {
                appendBattleLog('💥 KRYTYK! Użyto ${jutsu.name}! Zadano $finalDealt obrażeń!');
              } else {
                appendBattleLog('Użyto ${jutsu.name}! Zadano $finalDealt obrażeń.');
              }

              if (enemyHp <= 0) {
                Navigator.pop(ctx);

                if (isExamFight) {
                  setState(() => passedRankIndex = examTargetRank!);
                  addExperience(350);
                  addLog('🏆 ZDANO EGZAMIN na rangę: $ninjaRank!');
                  return;
                }

                int locLvl = shinobiLocations.firstWhere((l) => l.id == currentSelectedLocationId, orElse: () => shinobiLocations[0]).minLevel;
                int rewardRyo = template.isBoss ? (50 + locLvl * 5) : (10 + locLvl * 2);
                int expGained = template.isBoss ? (80 + locLvl * 8) : (14 + locLvl * 3);

                setState(() {
                  ryo += rewardRyo;
                  if (activeMissionIndex != null) {
                    final activeMission = allMissionsPool[activeMissionIndex!];
                    if (activeMission.type == MissionType.killCount && activeMission.targetEnemyId == template.id) {
                      currentMissionKills++;
                    } else if (activeMission.type == MissionType.bossHunt && activeMission.targetEnemyId == template.id) {
                      currentMissionKills = 1;
                    }
                  }
                });
                addExperience(expGained);
                addLog('🏆 Zwycięstwo nad $prefixTitle${template.name}! +$rewardRyo Ryo, +$expGained EXP.');

                // Zdobycie ekwipunku wyłącznie z pokonanego wroga
                bool shouldDropLoot = template.isBoss;
                if (!shouldDropLoot) {
                  int chance = forcePrefix == EnemyPrefix.strong ? 35 : 18;
                  shouldDropLoot = _rng.nextInt(100) < chance;
                }

                if (shouldDropLoot) {
                  _findLoot(guaranteedBossDrop: template.isBoss, dungeonBossSetGroup: dungeonBossSetGroup);
                }
              } else {
                enemyTurn();
                setBattleState(() {});
              }
            }

            void useBattleItem(Consumable item) {
              if (item.type == ConsumableType.smokeEscape) {
                if (template.isBoss || isExamFight) {
                  appendBattleLog('Bomba dymna nie działa na bossów!');
                  setBattleState(() {});
                  return;
                }
                useConsumable(item);
                Navigator.pop(ctx);
                addLog('💨 Ucieknięto z walki za pomocą Bomby Dymnej!');
                return;
              }

              if (item.type == ConsumableType.directDmg) {
                if (useConsumable(item)) {
                  int dmg = 35 + (level * 4);
                  enemyHp = max(0, enemyHp - dmg);
                  appendBattleLog('💥 Pieczęć Wybuchowa zadaje $dmg obrażeń!');
                  if (enemyHp <= 0) {
                    Navigator.pop(ctx);
                    addLog('🏆 Wróg rozerwany eksplozją Pieczęci!');
                    if (template.isBoss || _rng.nextInt(100) < 20) {
                      _findLoot(guaranteedBossDrop: template.isBoss, dungeonBossSetGroup: dungeonBossSetGroup);
                    }
                  } else {
                    enemyTurn();
                    setBattleState(() {});
                  }
                }
                return;
              }

              if (useConsumable(item)) {
                appendBattleLog('Użyto ${item.name}!');
                enemyTurn();
                setBattleState(() {});
              }
            }

            void openCombatBagDialog() {
              showDialog(
                context: context,
                builder: (bagCtx) => AlertDialog(
                  backgroundColor: const Color(0xFF191716),
                  title: const Text('🎒 Użyj zapasu w walce', style: TextStyle(color: Color(0xFFFFB74D), fontSize: 15)),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: bag.isEmpty
                        ? const Text('Brak przedmiotów w plecaku!', style: TextStyle(fontSize: 12, color: Colors.white54))
                        : ListView(
                            shrinkWrap: true,
                            children: bag.entries.map((entry) {
                              final item = allConsumables.firstWhere((c) => c.id == entry.key);
                              return ListTile(
                                dense: true,
                                leading: Text(item.icon, style: const TextStyle(fontSize: 22)),
                                title: Text('${item.name} (x${entry.value})', style: const TextStyle(fontSize: 12)),
                                subtitle: Text(item.statBonusText, style: const TextStyle(fontSize: 10, color: Color(0xFFFFD54F))),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00695C), padding: const EdgeInsets.symmetric(horizontal: 10)),
                                  onPressed: () {
                                    Navigator.pop(bagCtx);
                                    useBattleItem(item);
                                    setBattleState(() {});
                                  },
                                  child: const Text('Użyj', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
              height: 540,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(template.icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text('$prefixTitle${template.name}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: prefixColor)),
                        ],
                      ),
                      Text('$enemyHp / $enemyMaxHp HP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: enemyHp / enemyMaxHp, color: const Color(0xFFEF5350), backgroundColor: Colors.white12, minHeight: 7),
                  const SizedBox(height: 4),
                  Text('Statystyki: Crit $enemyCrit% | Kawarimi $enemyDodge% | Przebicie $enemyPierce%', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('Twoje HP: $hp / $maxHp', style: const TextStyle(fontSize: 12, color: Color(0xFF69F0AE), fontWeight: FontWeight.bold)),
                      Text('Twoje CP: $chakra / $maxChakra', style: const TextStyle(fontSize: 12, color: Color(0xFF40C4FF), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 90,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF0F0E0D), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                    child: ListView.builder(
                      reverse: true,
                      itemCount: battleLogHistory.length,
                      itemBuilder: (context, index) {
                        return Text(battleLogHistory[index], style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFFFFCC80)));
                      },
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: equippedJutsu.map((jutsu) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: jutsu.color.withAlpha(120),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () => executeJutsu(jutsu),
                            child: Text(jutsu.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00695C),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: openCombatBagDialog,
                          child: const Text('🎒 Plecak w walce', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF37474F),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            if (template.isBoss || isExamFight) {
                              appendBattleLog('Nie można uciec z tej walki!');
                              setBattleState(() {});
                              return;
                            }
                            Navigator.pop(ctx);
                            addLog('💨 Ucieczka z pola walki!');
                          },
                          child: const Text('💨 Ucieczka', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

  void _findLoot({bool guaranteedBossDrop = false, String? dungeonBossSetGroup}) {
    if (dungeonBossSetGroup != null && _rng.nextInt(100) < 35) {
      final bossPieces = bossExclusiveSetsPool.where((b) => b.setGroup == dungeonBossSetGroup).toList();
      final unownedPieces = bossPieces.where((p) => !equippedList.any((e) => e.name == p.baseName)).toList();

      final chosen = unownedPieces.isNotEmpty ? unownedPieces[_rng.nextInt(unownedPieces.length)] : bossPieces[_rng.nextInt(bossPieces.length)];

      List<GearAffix> affixes = [
        const GearAffix(type: AffixType.critRate, value: 12),
        const GearAffix(type: AffixType.armorPierce, value: 15),
      ];

      final drop = NinjaGear(
        name: chosen.baseName,
        rarity: ItemRarity.legendary,
        slot: chosen.slot,
        baseStat: chosen.baseStat,
        affixes: affixes,
        setGroup: chosen.setGroup,
        icon: chosen.icon,
      );

      NinjaGear currentGear = currentWeapon;
      switch (chosen.slot) {
        case GearSlot.weapon: currentGear = currentWeapon; break;
        case GearSlot.armor: currentGear = currentArmor; break;
        case GearSlot.helmet: currentGear = currentHelmet; break;
        case GearSlot.boots: currentGear = currentBoots; break;
        case GearSlot.trinket: currentGear = currentTrinket; break;
      }
      _showEquipDialog(newGear: drop, currentGear: currentGear, slot: chosen.slot);
      return;
    }

    final slot = GearSlot.values[_rng.nextInt(5)];
    final drop = _generateRandomGear(slot: slot, guaranteedBossDrop: guaranteedBossDrop);

    NinjaGear currentGear = currentWeapon;
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
    final locId = currentSelectedLocationId;
    final roll = _rng.nextInt(100);

    if (guaranteedBossDrop) {
      if (roll < 25) {
        rarity = ItemRarity.rare;
      } else if (roll < 80) {
        rarity = ItemRarity.epic;
      } else {
        rarity = ItemRarity.legendary;
      }
    } else {
      if (locId == 'loc_gate') {
        rarity = roll < 82 ? ItemRarity.common : (roll < 98 ? ItemRarity.rare : ItemRarity.epic);
      } else if (locId == 'loc_forest') {
        rarity = roll < 60 ? ItemRarity.common : (roll < 92 ? ItemRarity.rare : (roll < 99 ? ItemRarity.epic : ItemRarity.legendary));
      } else if (locId == 'loc_waves') {
        rarity = roll < 38 ? ItemRarity.common : (roll < 82 ? ItemRarity.rare : (roll < 97 ? ItemRarity.epic : ItemRarity.legendary));
      } else if (locId == 'loc_valley') {
        rarity = roll < 18 ? ItemRarity.common : (roll < 63 ? ItemRarity.rare : (roll < 91 ? ItemRarity.epic : ItemRarity.legendary));
      } else {
        rarity = roll < 5 ? ItemRarity.common : (roll < 40 ? ItemRarity.rare : (roll < 82 ? ItemRarity.epic : ItemRarity.legendary));
      }
    }

    final arch = standardArchetypesPool.where((a) => a.slot == slot).toList();
    final chosen = arch[_rng.nextInt(arch.length)];

    String prefix = '';
    if (rarity == ItemRarity.rare) prefix = 'Mistrzowski ';
    if (rarity == ItemRarity.epic) prefix = 'Pradawny ';
    if (rarity == ItemRarity.legendary) prefix = 'Legendarny ';

    List<GearAffix> generatedAffixes = [];
    int affixesCount = rarity == ItemRarity.common ? 0 : (rarity == ItemRarity.rare ? 1 : (rarity == ItemRarity.epic ? 2 : 3));

    final availableTypes = List<AffixType>.from(AffixType.values)..shuffle(_rng);
    for (int i = 0; i < affixesCount && i < availableTypes.length; i++) {
      final type = availableTypes[i];
      int val = 0;
      switch (type) {
        case AffixType.critRate: val = 4 + (rarity.index * 4) + _rng.nextInt(3); break;
        case AffixType.dodgeRate: val = 3 + (rarity.index * 3) + _rng.nextInt(3); break;
        case AffixType.armorPierce: val = 5 + (rarity.index * 4) + _rng.nextInt(4); break;
        case AffixType.lifeSteal: val = 4 + (rarity.index * 3) + _rng.nextInt(3); break;
        case AffixType.hpRegen: val = 2 + (rarity.index * 2); break;
        case AffixType.chakraRegen: val = 2 + (rarity.index * 2); break;
        case AffixType.bonusHp: val = 15 + (rarity.index * 15); break;
        case AffixType.bonusChakra: val = 12 + (rarity.index * 12); break;
      }
      generatedAffixes.add(GearAffix(type: type, value: val));
    }

    return NinjaGear(
      name: '$prefix${chosen.baseName}',
      rarity: rarity,
      slot: slot,
      baseStat: chosen.baseStat + (rarity.index * 4) + _rng.nextInt(2),
      affixes: generatedAffixes,
      setGroup: chosen.setGroup,
      isSoulbound: false,
      icon: chosen.icon,
    );
  }

  void _showEquipDialog({required NinjaGear newGear, required NinjaGear currentGear, required GearSlot slot}) {
    String slotName = slot == GearSlot.weapon ? 'Broń' : (slot == GearSlot.armor ? 'Pancerz' : (slot == GearSlot.helmet ? 'Głowa' : (slot == GearSlot.boots ? 'Buty' : 'Talizman')));
    int diff = newGear.effectiveStat - currentGear.effectiveStat;
    String diffText = diff > 0 ? '+$diff' : '$diff';
    Color diffColor = diff > 0 ? const Color(0xFF69F0AE) : (diff < 0 ? const Color(0xFFFF5252) : Colors.grey);
    final sellValue = newGear.sellPrice;
    final bool canStash = equipmentStash.length < 10;

    bool isBetter = newGear.effectiveStat > currentGear.effectiveStat || (newGear.effectiveStat == currentGear.effectiveStat && newGear.affixes.length >= currentGear.affixes.length);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF191716),
        title: Row(
          children: [
            Text('Odnaleziono: $slotName!', style: const TextStyle(color: Color(0xFFFFB74D), fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            if (newGear.isBossSet)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                child: const Text('SET BOSSA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isBetter ? const Color(0xFF1B5E20).withAlpha(120) : const Color(0xFFB71C1C).withAlpha(120),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isBetter ? '💡 Sugestia: Ten sprzęt jest silniejszy!' : '⚠️ Sugestia: Ten sprzęt jest słabszy.',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isBetter ? const Color(0xFF69F0AE) : const Color(0xFFFF8A80)),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF141211),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: newGear.borderColor, width: newGear.borderWidth),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(newGear.icon, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('NOWY: ${newGear.displayName}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: newGear.borderColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text('Moc: +${newGear.effectiveStat} ', style: const TextStyle(fontSize: 12)),
                      Text('($diffText)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: diffColor)),
                    ],
                  ),
                  Text('Wartość: ${newGear.marketValue} Ryo (Złomowanie: $sellValue Ryo)', style: const TextStyle(fontSize: 10, color: Color(0xFFFFD54F))),
                  if (newGear.setGroup != 'none')
                    Text('Zestaw: ${newGear.setGroup.toUpperCase()}', style: const TextStyle(fontSize: 11, color: Color(0xFF80D8FF))),
                  if (newGear.affixes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ...newGear.affixes.map((a) => Text(a.label, style: const TextStyle(fontSize: 11, color: Color(0xFFFFD54F)))),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF141211),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: currentGear.borderColor, width: currentGear.borderWidth),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(currentGear.icon, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('POSIADANY: ${currentGear.displayName}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: currentGear.borderColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('Moc: +${currentGear.effectiveStat}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (isBetter) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      addLog('Odrzucono: ${newGear.displayName}.');
                    },
                    child: const Text('Odrzuć', style: TextStyle(color: Colors.grey)),
                  ),
                  if (canStash)
                    TextButton(
                      onPressed: () {
                        setState(() => equipmentStash.add(newGear));
                        _saveGameData();
                        Navigator.pop(ctx);
                        addLog('📦 Schowano [${newGear.displayName}] do plecaka.');
                      },
                      child: const Text('Zachowaj', style: TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100), padding: const EdgeInsets.symmetric(vertical: 12)),
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
                  child: const Text('Zamień ⭐', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
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
                    child: const Text('Zamień mimo to', style: TextStyle(color: Colors.grey)),
                  ),
                  if (canStash)
                    TextButton(
                      onPressed: () {
                        setState(() => equipmentStash.add(newGear));
                        _saveGameData();
                        Navigator.pop(ctx);
                        addLog('📦 Schowano [${newGear.displayName}] do plecaka.');
                      },
                      child: const Text('Zachowaj', style: TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF37474F), padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    addLog('Odrzucono: ${newGear.displayName}.');
                  },
                  child: const Text('Odrzuć ⭐', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showItemDetailsDialog(String slotName, NinjaGear gear) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF191716),
        title: Row(
          children: [
            Text(gear.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text('$slotName: ${gear.displayName}', style: TextStyle(color: gear.borderColor, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (gear.isBossSet)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                child: const Text('UNIKALNY ZESTAW BOSSA LOCHU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            Text('Rzadkość: ${gear.rarityLabel}', style: TextStyle(color: gear.color, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Moc bazowa: +${gear.effectiveStat}', style: const TextStyle(fontSize: 13)),
            Text('Wycena rynkowa: ${gear.marketValue} Ryo (Złom: ${gear.sellPrice} Ryo)', style: const TextStyle(fontSize: 12, color: Color(0xFFFFD54F))),
            if (gear.setGroup != 'none')
              Text('Zestaw (Set): ${gear.setGroup.toUpperCase()}', style: const TextStyle(fontSize: 12, color: Color(0xFF80D8FF))),
            if (gear.affixes.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Text('Dodatkowe atuty:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D))),
              ...gear.affixes.map((a) => Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(a.label, style: const TextStyle(fontSize: 12, color: Color(0xFFFFE082))),
              )),
            ],
            const SizedBox(height: 10),
            Text(gear.isSoulbound ? '📜 Przedmiot zapieczętowany (bezpieczny)' : '⚠️ Przedmiot niezabezpieczony (Koszt pieczęci: ${gear.sealingCost} Ryo)', style: TextStyle(fontSize: 11, color: gear.isSoulbound ? const Color(0xFF69F0AE) : const Color(0xFFFF5252))),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zamknij', style: TextStyle(color: Colors.grey)))],
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
              const Text('Wybierz lokację eksploracji:', style: TextStyle(color: Color(0xFFFFAB91), fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: shinobiLocations.map((loc) {
                    final bool isLocked = level < loc.minLevel;
                    return Card(
                      color: const Color(0xFF1B1917),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Text(loc.icon, style: const TextStyle(fontSize: 26)),
                        title: Text(loc.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isLocked ? Colors.white38 : Colors.white)),
                        subtitle: Text('Wymagany poziom: ${loc.minLevel}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLocked ? const Color(0xFF37474F) : const Color(0xFFE65100),
                          ),
                          onPressed: () {
                            if (isLocked) {
                              showActionBlockedMessage('🚫 Wymagany poziom ${loc.minLevel}! (Masz Lvl $level)');
                              return;
                            }
                            Navigator.pop(ctx);
                            leaveVillage(loc);
                          },
                          child: Text(isLocked ? 'Zablokowane' : 'Wyrusz', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                actions: [
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: Color(0xFFFFB74D)),
                    tooltip: 'Pomoc',
                    onPressed: () => showHelpDialog(context),
                  ),
                ],
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
                      backgroundColor: hasEscapeScroll ? const Color(0xFF1B5E20) : const Color(0xFF263238),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      if (!hasEscapeScroll) {
                        showActionBlockedMessage('🔒 Brak Zwoju Powrotu! Musisz go znaleźć w terenie.');
                        return;
                      }
                      returnToVillage();
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        hasEscapeScroll ? '📜 Zwój (Użyj)' : '🔒 Zablokowane',
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: hasEscapeScroll ? Colors.white : Colors.white38,
                        ),
                      ),
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
