import 'package:flutter/material.dart';

void main() => runApp(const MindCoreApp());

const bg = Color(0xFF0B0F13);
const panel = Color(0xFF111820);
const line = Color(0xFF2B3944);
const accent = Color(0xFF76D7E8);
const ink = Color(0xFFE8EEF2);
const muted = Color(0xFF93A2AD);

class MindCoreApp extends StatelessWidget {
  const MindCoreApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MindCore AI',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(primary: accent, surface: panel),
      useMaterial3: true,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(backgroundColor: bg, foregroundColor: ink),
      cardTheme: CardThemeData(color: panel, elevation: 0, shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: line),
      )),
    ),
    home: const Dashboard(),
  );
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int tab = 0;
  final controller = TextEditingController();
  final messages = <String>[];
  bool offline = true;

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final titles = ['COMMAND CENTER', 'LOCAL CHAT', 'APP CONTROL', 'MODEL BAY', 'PRIVACY'];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('MINDCORE', style: TextStyle(fontSize: 18, letterSpacing: 3, fontWeight: FontWeight.w800)),
          Text('LOCAL INTELLIGENCE SYSTEM / 01', style: TextStyle(fontSize: 9, color: muted, letterSpacing: 1.3)),
        ]),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF386B58)), borderRadius: BorderRadius.circular(5)),
            child: const Row(children: [Icon(Icons.circle, color: Color(0xFF6AD3A0), size: 7), SizedBox(width: 6), Text('OFFLINE', style: TextStyle(fontSize: 10, letterSpacing: 1))]),
          ))),
        ],
      ),
      body: SafeArea(child: Column(children: [
        Expanded(child: IndexedStack(index: tab, children: [
          _home(),
          _chat(),
          _apps(),
          _models(),
          _privacy(),
        ])),
        _nav(),
      ])),
    );
  }

  Widget _home() => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('SYSTEM OVERVIEW', style: TextStyle(color: muted, fontSize: 10, letterSpacing: 2)),
    const SizedBox(height: 8),
    const Text('Your device.\nYour intelligence.', style: TextStyle(color: ink, fontSize: 30, height: 1.12, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    const Text('Private by design. Runs locally when a compatible model is installed.', style: TextStyle(color: muted, height: 1.4)),
    const SizedBox(height: 20),
    Row(children: [
      Expanded(child: _metric('LLM ENGINE', 'NOT LOADED', Icons.memory)),
      const SizedBox(width: 10),
      Expanded(child: _metric('NETWORK', 'DISABLED', Icons.wifi_off)),
    ]),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _metric('ACTION GUARD', 'ENABLED', Icons.shield_outlined)),
      const SizedBox(width: 10),
      Expanded(child: _metric('SCREEN ACCESS', 'NOT ENABLED', Icons.screen_search_desktop_outlined)),
    ]),
    const SizedBox(height: 20),
    const Text('OPERATIONS', style: TextStyle(color: muted, fontSize: 10, letterSpacing: 2)),
    const SizedBox(height: 8),
    _operation(Icons.chat_outlined, 'Local AI chat', 'Text assistant • model required', () => setState(() => tab = 1)),
    _operation(Icons.apps_outlined, 'App control', 'Add apps you choose to manage', () => setState(() => tab = 2)),
    _operation(Icons.memory, 'Model manager', 'Small-model-first • local files', () => setState(() => tab = 3)),
    _operation(Icons.lock_outline, 'Privacy & permissions', 'No telemetry • confirmation required', () => setState(() => tab = 4)),
    const SizedBox(height: 12),
    const Text('Prototype build: UI is active; local inference and Android automation are not yet connected.', style: TextStyle(color: muted, fontSize: 11)),
  ]);

  Widget _metric(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: panel, border: Border.all(color: line), borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: accent, size: 20), const SizedBox(height: 14),
      Text(label, style: const TextStyle(color: muted, fontSize: 9, letterSpacing: 1)),
      const SizedBox(height: 5),
      Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _operation(IconData icon, String title, String subtitle, VoidCallback tap) => Card(
    child: ListTile(onTap: tap, leading: Icon(icon, color: accent), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)), subtitle: Text(subtitle, style: const TextStyle(color: muted, fontSize: 11)), trailing: const Icon(Icons.chevron_right, color: muted)),
  );

  Widget _chat() => Column(children: [
    const Padding(padding: EdgeInsets.all(18), child: Align(alignment: Alignment.centerLeft, child: Text('LOCAL CHAT / SESSION 01', style: TextStyle(color: muted, fontSize: 10, letterSpacing: 1.5)))),
    Expanded(child: messages.isEmpty
      ? const Center(child: Padding(padding: EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.memory, size: 44, color: accent), SizedBox(height: 12),
        Text('Local model not connected', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        SizedBox(height: 6), Text('Install a compatible model and connect the native runtime to enable AI responses.', textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.4)),
      ])))
      : ListView(padding: const EdgeInsets.all(16), children: messages.map((m) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Text(m)))).toList()),
    ),
    Padding(padding: const EdgeInsets.all(12), child: Row(children: [
      Expanded(child: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Write a message…', filled: true, fillColor: panel, border: OutlineInputBorder(), isDense: true))),
      const SizedBox(width: 8),
      IconButton.filled(onPressed: () { if (controller.text.trim().isNotEmpty) { setState(() { messages.add('YOU  /  ${controller.text.trim()}'); controller.clear(); }); } }, icon: const Icon(Icons.arrow_upward), color: bg, style: IconButton.styleFrom(backgroundColor: accent)),
    ])),
  ]);

  Widget _apps() => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('APP CONTROL', style: TextStyle(color: muted, fontSize: 10, letterSpacing: 2)),
    const SizedBox(height: 12),
    const Text('Choose what MindCore may assist with.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    const Text('Apps must be added intentionally. Android Accessibility permission is granted by you in system settings; it does not grant unrestricted access to every app.', style: TextStyle(color: muted, height: 1.45)),
    const SizedBox(height: 18),
    _operation(Icons.add_box_outlined, 'Add an app', 'Prototype only — package picker not connected', () => _notice('App selection will be connected in the Android integration phase.')),
    _operation(Icons.screen_search_desktop_outlined, 'Enable screen reading', 'Requires explicit Accessibility permission', () => _notice('Accessibility settings link is not connected in this prototype.')),
    _operation(Icons.verified_user_outlined, 'Action confirmation', 'Always required for sensitive actions', () => _notice('Sensitive actions remain disabled until a trusted executor is implemented.')),
  ]);

  Widget _models() => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('MODEL BAY', style: TextStyle(color: muted, fontSize: 10, letterSpacing: 2)),
    const SizedBox(height: 12),
    const Text('Small model first.', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    const Text('No model is bundled in this prototype. Import and compatibility checks are future integration work.', style: TextStyle(color: muted, height: 1.45)),
    const SizedBox(height: 18),
    _metric('ACTIVE MODEL', 'NONE', Icons.memory),
    const SizedBox(height: 10),
    _operation(Icons.folder_open, 'Import local model', 'GGUF / runtime compatibility not connected', () => _notice('Local model import will be added with the native inference engine.')),
    _operation(Icons.speed, 'Resource policy', 'Lazy load • cancel on memory pressure', () => _notice('Live RAM and thermal telemetry are not connected yet.')),
  ]);

  Widget _privacy() => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('PRIVACY & TRUST', style: TextStyle(color: muted, fontSize: 10, letterSpacing: 2)),
    const SizedBox(height: 12),
    const Text('Nothing leaves by default.', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    SwitchListTile(value: offline, onChanged: (v) => setState(() => offline = v), activeColor: accent, contentPadding: EdgeInsets.zero, title: const Text('Strict offline mode'), subtitle: const Text('UI preference only; network access is not implemented in this prototype.', style: TextStyle(color: muted, fontSize: 11))),
    const Divider(color: line),
    _operation(Icons.lock_outline, 'Encrypted local history', 'Not implemented yet', () => _notice('Encrypted storage is planned; do not store sensitive data in this prototype.')),
    _operation(Icons.timer_outlined, '24-hour retention', 'Not implemented yet', () => _notice('Retention cleanup is planned for the storage integration phase.')),
    _operation(Icons.thermostat_outlined, 'Thermal protection', 'Not connected to device telemetry', () => _notice('Thermal monitoring is planned for native integration.')),
    const SizedBox(height: 12),
    const Text('This prototype does not claim to provide complete local AI, encryption, or device automation yet.', style: TextStyle(color: muted, fontSize: 11, height: 1.4)),
  ]);

  Widget _nav() => Container(
    decoration: const BoxDecoration(color: panel, border: Border(top: BorderSide(color: line))),
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _navItem(Icons.grid_view, 'Home', 0),
      _navItem(Icons.chat_bubble_outline, 'Chat', 1),
      _navItem(Icons.apps, 'Apps', 2),
      _navItem(Icons.memory, 'Models', 3),
      _navItem(Icons.shield_outlined, 'Privacy', 4),
    ]),
  );

  Widget _navItem(IconData icon, String label, int index) => InkWell(
    onTap: () => setState(() => tab = index),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 19, color: tab == index ? accent : muted),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(fontSize: 9, color: tab == index ? accent : muted)),
    ])),
  );

  void _notice(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
