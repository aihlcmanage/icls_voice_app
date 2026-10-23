import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const IclsVoiceApp());
}

class IclsVoiceApp extends StatelessWidget {
  const IclsVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICLS Voice App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const VoiceButtonPage(),
    );
  }
}

class VoiceButtonPage extends StatefulWidget {
  const VoiceButtonPage({super.key});

  @override
  State<VoiceButtonPage> createState() => _VoiceButtonPageState();
}

class _VoiceButtonPageState extends State<VoiceButtonPage> {
  // 音声プレイヤーのインスタンス
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 再生中のファイル名（画面表示用）
  String _statusMessage = 'ボタンを押して音声を再生';

  // ==========================================
  // 音声ファイルのリスト（ここにファイル名を追加していきます）
  // ==========================================
  final List<String> audioFiles = [
    'test.wav',
    // 例: '1_initial_check.wav',
    // 例: '2_call_help.wav',
  ];

  // 音声を再生する関数
  Future<void> _playSound(String fileName) async {
    try {
      // audioplayersのSource.assetを使用して再生
      // パスは pubspec.yaml で指定した assets/audio/ からの相対、またはフルパスを指定
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/$fileName'));
      
      setState(() {
        _statusMessage = '再生中: $fileName';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '再生エラー: $e';
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ICLS シмуляレーション音声アプリ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ステータス表示
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            // 動的ボタン生成グリッド
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 横に並べるボタンの数
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.0,
                ),
                itemCount: audioFiles.length,
                itemBuilder: (context, index) {
                  final fileName = audioFiles[index];
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 2,
                    ),
                    onPressed: () => _playSound(fileName),
                    child: Text(
                      fileName,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}