import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/services.dart'; // AssetManifest用

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
  String _statusMessage = '音声リストを読み込み中...';
  List<String> audioFiles = [];

  @override
  void initState() {
    super.initState();
    _loadAudioAssets();
  }

  // ==========================================
  // assets/audio/ フォルダ内のファイルを自動スキャンして取得
  // ==========================================
  Future<void> _loadAudioAssets() async {
    try {
      // 最新のFlutter仕様（AssetManifest API）を利用してアセット一覧を取得
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final allAssets = manifest.listAssets();

      // 'assets/audio/' 階層にあるファイル、かつ '.wav' で終わるものを自動抽出
      final filteredFiles = allAssets.where((path) {
        return path.startsWith('assets/audio/') && path.toLowerCase().endsWith('.wav');
      }).map((path) {
        // 'assets/audio/ファイル名.wav' からファイル名部分だけを抽出
        return path.split('/').last;
      }).toList();

      setState(() {
        audioFiles = filteredFiles;
        if (audioFiles.isEmpty) {
          _statusMessage = 'assets/audio/ 内に音声が見つかりませんでした';
        } else {
          _statusMessage = '音声ファイル数: ${audioFiles.length} 件（準備完了）';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'アセット読み込みエラー: $e';
      });
    }
  }

  // ブラウザの標準機能（HTMLAudioElement）でダイレクトにWAVを再生
  void _playSound(String fileName) {
    try {
      final encodedFileName = Uri.encodeComponent(fileName);
      final assetPath = 'assets/audio/$encodedFileName';

      final audio = html.AudioElement(assetPath);
      
      audio.play().then((_) {
        setState(() {
          _statusMessage = '再生中: $fileName';
        });
      }).catchError((e) {
        setState(() {
          _statusMessage = '再生エラー（ブラウザ拒否）: $e';
        });
      });

      audio.onEnded.listen((_) {
        setState(() {
          _statusMessage = '再生終了';
        });
      });
      
    } catch (e) {
      setState(() {
        _statusMessage = 'エラー: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ICLS シミュレーション音声アプリ（自動全反映）'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
            Expanded(
              child: audioFiles.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: audioFiles.length,
                      itemBuilder: (context, index) {
                        final fileName = audioFiles[index];

                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: () => _playSound(fileName),
                          child: Text(
                            fileName, // ファイル名をそのままボタンに表示
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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