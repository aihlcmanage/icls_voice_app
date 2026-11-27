import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const IclsVoiceApp());
}

class IclsVoiceApp extends StatelessWidget {
  const IclsVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICLS シミュレーション音声',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ScenarioVoicePage(),
    );
  }
}

class ScenarioVoicePage extends StatefulWidget {
  const ScenarioVoicePage({super.key});

  @override
  State<ScenarioVoicePage> createState() => _ScenarioVoicePageState();
}

class _ScenarioVoicePageState extends State<ScenarioVoicePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AudioPlayer _audioPlayer;
  late Uint8List _silentWavBytes;

  StreamSubscription<void>? _completeSub;
  String _statusMessage = '設定ファイルを読み込み中...';
  bool _isLoading = true;
  int _playRequestId = 0;

  List<dynamic> _scenario1Files = [];
  List<dynamic> _scenario2Files = [];
  List<dynamic> _scenario3Files = [];

  List<dynamic> _scenario1Adlibs = [];
  List<dynamic> _scenario2Adlibs = [];
  List<dynamic> _scenario3Adlibs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _audioPlayer = AudioPlayer();
    _silentWavBytes = _createSilentWav(durationMs: 250, sampleRate: 16000);

    _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        if (_statusMessage.startsWith('再生中:')) {
          _statusMessage = '再生完了（タップして再生）';
        }
      });
    });

    _loadConfigJson();
  }

  @override
  void dispose() {
    _completeSub?.cancel();
    _tabController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Uint8List _createSilentWav({int durationMs = 250, int sampleRate = 16000}) {
    const numChannels = 1;
    const bitsPerSample = 16;
    final numSamples = (sampleRate * durationMs) ~/ 1000;
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final blockAlign = numChannels * (bitsPerSample ~/ 8);
    final dataSize = numSamples * blockAlign;
    final totalSize = 44 + dataSize;

    final buffer = ByteData(totalSize);

    void writeAscii(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        buffer.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    writeAscii(8, 'WAVE');

    writeAscii(12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, numChannels, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, byteRate, Endian.little);
    buffer.setUint16(32, blockAlign, Endian.little);
    buffer.setUint16(34, bitsPerSample, Endian.little);

    writeAscii(36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);

    return buffer.buffer.asUint8List();
  }

  Future<void> _loadConfigJson() async {
    try {
      final jsonString = await rootBundle.loadString('assets/audio_config.json');
      final data = json.decode(jsonString);

      if (!mounted) return;
      setState(() {
        _scenario1Files = List<dynamic>.from(data['scenario1'] ?? []);
        _scenario2Files = List<dynamic>.from(data['scenario2'] ?? []);
        _scenario3Files = List<dynamic>.from(data['scenario3'] ?? []);

        _scenario1Adlibs = List<dynamic>.from(data['scenario1_adlib'] ?? []);
        _scenario2Adlibs = List<dynamic>.from(data['scenario2_adlib'] ?? []);
        _scenario3Adlibs = List<dynamic>.from(data['scenario3_adlib'] ?? []);

        _isLoading = false;
        _statusMessage = '準備完了（タップして再生）';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _statusMessage = 'JSON読み込みエラー: $e';
      });
    }
  }

  Future<void> _playSound(String fileName, String label) async {
    final int currentRequestId = ++_playRequestId;

    try {
      if (!mounted) return;
      setState(() {
        _statusMessage = '接続待機中: $label';
      });

      await _audioPlayer.stop();
      if (currentRequestId != _playRequestId) return;

      await _audioPlayer.setVolume(0.0);
      await _audioPlayer.play(BytesSource(_silentWavBytes));
      await Future.delayed(const Duration(milliseconds: 220));
      if (currentRequestId != _playRequestId) return;

      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);
      if (currentRequestId != _playRequestId) return;

      if (!mounted) return;
      setState(() {
        _statusMessage = '再生中: $label';
      });

      await _audioPlayer.play(AssetSource('audio/$fileName'));
    } catch (e) {
      if (currentRequestId != _playRequestId || !mounted) return;
      setState(() {
        _statusMessage = '再生エラー: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ICLS 音声シミュレーター',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        toolbarHeight: 40,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          indicatorWeight: 4,
          tabs: const [
            Tab(text: 'シナリオ 1'),
            Tab(text: 'シナリオ 2'),
            Tab(text: 'シナリオ 3'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              color: Colors.blue.shade50,
              child: Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTwoZoneLayout(
                          _scenario1Files,
                          _scenario1Adlibs,
                          'シナリオ1 定型文',
                          'アドリブ・反応（男1）',
                        ),
                        _buildTwoZoneLayout(
                          _scenario2Files,
                          _scenario2Adlibs,
                          'シナリオ2 定型文',
                          'アドリブ・反応（男2）',
                        ),
                        _buildTwoZoneLayout(
                          _scenario3Files,
                          _scenario3Adlibs,
                          'シナリオ3 定型文',
                          'アドリブ・反応（女）',
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoZoneLayout(
    List<dynamic> scenarioFiles,
    List<dynamic> adlibFiles,
    String fixedTitle,
    String adlibTitle,
  ) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: _buildZoneCard(
              title: fixedTitle,
              color: Colors.blue.shade100,
              badgeColor: Colors.blue.shade800,
              items: scenarioFiles,
              emptyText: 'シナリオ用音声がありません',
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            flex: 5,
            child: _buildZoneCard(
              title: adlibTitle,
              color: Colors.orange.shade100,
              badgeColor: Colors.orange.shade900,
              items: adlibFiles,
              emptyText: 'アドリブ音声がありません',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneCard({
    required String title,
    required Color color,
    required Color badgeColor,
    required List<dynamic> items,
    required String emptyText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final int crossAxisCount = items.length > 8 ? 3 : 2;
                      final int rows = (items.length / crossAxisCount).ceil();
                      final double minRowHeight = 46.0;
                      final double totalSpacing = (rows - 1) * 6.0;
                      final double availableHeight =
                          constraints.maxHeight - totalSpacing;
                      final double rowHeight =
                          (availableHeight / rows) < minRowHeight
                              ? minRowHeight
                              : (availableHeight / rows);
                      final double itemWidth =
                          (constraints.maxWidth - (crossAxisCount - 1) * 6.0) /
                              crossAxisCount;
                      final double childAspectRatio = itemWidth / rowHeight;

                      return GridView.builder(
                        physics: const ClampingScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index] as Map<String, dynamic>;
                          final fileName = item['file']?.toString() ?? '';
                          final label = item['label']?.toString() ?? '';

                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              elevation: 2,
                              padding: const EdgeInsets.all(4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: () => _playSound(fileName, label),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}