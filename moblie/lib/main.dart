import 'package:flutter/material.dart';

import 'clipboard/clipboard_watcher.dart';
import 'data.dart';
import 'screens/task_detail.dart';
import 'screens/ticket_list.dart';
import 'test_image.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await clipboardWatcher.start();
  runApp(const SnapDropApp());
}

class SnapDropApp extends StatelessWidget {
  const SnapDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnapDrop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF6D4AFF), useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  Future<void> _copyTestImage() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Không hiện snackbar: chip / banner gợi ý tự xuất hiện là đủ.
      await clipboardWatcher.writeTestImage(await makeTestImage());
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Chi tiết YC-1023' : 'Yêu cầu của tôi'),
        actions: [
          ListenableBuilder(
            listenable: appState,
            builder: (context, _) => PopupMenuButton<Role>(
              tooltip: 'Vai trò',
              initialValue: appState.role,
              onSelected: appState.setRole,
              itemBuilder: (_) => [for (final r in Role.values) PopupMenuItem(value: r, child: Text(r.label))],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(children: [const Icon(Icons.badge_outlined, size: 18), const SizedBox(width: 4), Text(appState.role.label)]),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copy ảnh test vào clipboard',
            icon: const Text('🧪', style: TextStyle(fontSize: 20)),
            onPressed: _copyTestImage,
          ),
        ],
      ),
      // Chỉ dựng tab đang mở để ô đính kèm của tab kia không đăng ký.
      body: _tab == 0 ? const TaskDetailScreen() : const TicketListScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Có ô đính kèm'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Không có ô đính kèm'),
        ],
      ),
    );
  }
}
