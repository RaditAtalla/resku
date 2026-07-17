import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/utils/design_system.dart';
import '../../../../core/utils/local_llm_service.dart';

class CopilotChatWidget extends StatefulWidget {
  final String systemContext;
  final VoidCallback onClose;

  const CopilotChatWidget({
    super.key,
    required this.systemContext,
    required this.onClose,
  });

  @override
  State<CopilotChatWidget> createState() => _CopilotChatWidgetState();
}

class _CopilotChatWidgetState extends State<CopilotChatWidget> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isInitializing = false;
  bool _isGenerating = false;
  bool _isDemoMode = false;
  String _modelStatus = 'Offline'; // Offline, Initializing, Ready, Error
  StreamSubscription<String>? _llmSubscription;

  final List<String> _suggestions = [
    'Summarize critical survivors',
    'List vulnerable bridges',
    'Find component centroids',
  ];

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  @override
  void dispose() {
    _llmSubscription?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _checkModelStatus() {
    final llm = LocalLlmService();
    if (!llm.isSupported) {
      setState(() {
        _modelStatus = 'Unsupported';
      });
    } else if (llm.isInitialized) {
      setState(() {
        _modelStatus = 'Ready';
      });
    } else {
      setState(() {
        _modelStatus = 'Offline';
      });
    }
  }

  Future<void> _initializeModel() async {
    setState(() {
      _isInitializing = true;
      _modelStatus = 'Initializing';
    });

    try {
      // Initialize model using MLC Qwen 1.5B (standard browser target)
      await LocalLlmService().initialize('qwen-1.5b-disaster');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _modelStatus = 'Ready';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _modelStatus = 'Error';
          _messages.add({
            'role': 'assistant',
            'content': 'Error initializing Local LLM: $e\nMake sure your browser supports WebGPU and you have an active network connection for the initial weights fetch.'
          });
        });
      }
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _messages.add({'role': 'assistant', 'content': ''}); // Placeholder for streaming output
      _isGenerating = true;
    });

    _scrollToBottom();
    _inputController.clear();

    final systemPrompt = widget.systemContext;
    final userPrompt = text;

    if (_isDemoMode) {
      _llmSubscription?.cancel();
      
      final String responseText;
      final query = text.toLowerCase();
      
      if (query.contains('critical') || query.contains('survivor') || query.contains('triage')) {
        responseText = "Based on the live SPAN graph analysis, Budi Santoso is the highest priority survivor needing triage (Status: CRITICAL, Score: 95, Needs: Splint, Water, Bleeding Control). "
            "Eko Wijaya is also critical (Status: CRITICAL, Score: 45, Needs: Splint, First Aid Kit). "
            "Aditya Pratama and Dewi Lestari are currently flagged as INJURED. I recommend dispatching a rescue unit to locate Budi Santoso immediately.";
      } else if (query.contains('centroid') || query.contains('hub') || query.contains('staging')) {
        responseText = "The network components have been topological mapped to identify optimal staging areas. "
            "Aditya Pratama has been selected as the topological centroid (medoid). "
            "Focusing staging operations at Aditya's coordinates (-6.1745, 106.8260) minimizes the average multi-hop hop-count to all other connected peers in the mesh, reducing data propagation latency.";
      } else if (query.contains('bridge') || query.contains('relay') || query.contains('articulation') || query.contains('partition') || query.contains('split')) {
        responseText = "Tarjan's DFS Articulation Points algorithm has identified critical communication relays: "
            "Budi Santoso, Aditya Pratama, and Eko Wijaya. "
            "If any of these nodes fail or power down, the peer-to-peer ad-hoc network will partition. "
            "WARNING: Budi Santoso's battery is currently at 12%. Link loss is imminent, which will isolate Siti Rahma from the rest of the mesh. Deliver power supplies or dispatch units to Budi immediately.";
      } else {
        responseText = "Disaster Copilot (Local Demo Mode): I am analyzing the active SPAN ad-hoc network topology around Monas, Jakarta. "
            "I can help you list vulnerable communication bridges, locate component centroids for staging areas, or prioritize critical survivors. "
            "Try asking: 'Summarize critical survivors', 'List vulnerable bridges', or 'Find component centroids'.";
      }

      int wordIndex = 0;
      final words = responseText.split(' ');
      Timer.periodic(const Duration(milliseconds: 55), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (wordIndex >= words.length) {
          timer.cancel();
          setState(() {
            _isGenerating = false;
          });
          _scrollToBottom();
          return;
        }
        setState(() {
          final lastIndex = _messages.length - 1;
          final prevContent = _messages[lastIndex]['content'] ?? '';
          _messages[lastIndex]['content'] = prevContent + (wordIndex == 0 ? '' : ' ') + words[wordIndex];
          wordIndex++;
        });
        _scrollToBottom();
      });
      return;
    }

    _llmSubscription?.cancel();
    
    // Start generating tokens
    _llmSubscription = LocalLlmService().generate(systemPrompt, userPrompt).listen(
      (token) {
        if (mounted) {
          setState(() {
            final lastIndex = _messages.length - 1;
            final prevContent = _messages[lastIndex]['content'] ?? '';
            _messages[lastIndex]['content'] = prevContent + token;
          });
          _scrollToBottom();
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            final lastIndex = _messages.length - 1;
            _messages[lastIndex]['content'] = 'Inference Error: $err';
            _isGenerating = false;
          });
          _scrollToBottom();
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _isGenerating = false;
          });
          _scrollToBottom();
        }
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _enableDemoMode() {
    setState(() {
      _isDemoMode = true;
      _modelStatus = 'Ready';
      _isInitializing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: AppColors.border, width: 1.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.grayBg,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_alt, color: AppColors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Disaster Copilot AI',
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildStatusBadge(),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.muted, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Messages / Idle Panel
          Expanded(
            child: _buildBody(),
          ),

          // Message Input Box (only shown if model initialized)
          if (_modelStatus == 'Ready') _buildInputBox(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String label;

    switch (_modelStatus) {
      case 'Ready':
        badgeColor = AppColors.safe;
        label = 'ONLINE (LOCAL)';
        break;
      case 'Initializing':
        badgeColor = AppColors.injured;
        label = 'INITIALIZING...';
        break;
      case 'Unsupported':
        badgeColor = AppColors.critical;
        label = 'WEBGPU BLOCKED';
        break;
      case 'Error':
        badgeColor = AppColors.critical;
        label = 'ERROR';
        break;
      case 'Offline':
      default:
        badgeColor = AppColors.muted;
        label = 'OFFLINE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        border: Border.all(color: badgeColor, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontFamily: 'monospace',
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_modelStatus) {
      case 'Unsupported':
        return _buildSetupPanel();
      case 'Offline':
        return _buildSetupPanel();
      case 'Initializing':
        return _buildInitializingPanel();
      case 'Error':
        return _buildErrorPanel();
      case 'Ready':
      default:
        return _buildChatListPanel();
    }
  }

  Widget _buildInitializingPanel() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.orange),
          const SizedBox(height: 16),
          const Text(
            'Downloading & Compiling LLM...',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyBold,
          ),
          const SizedBox(height: 8),
          const Text(
            'Downloading Qwen 1.5B model weights (~1.2GB) and compiling WebGPU shaders. This can take 1-2 minutes depending on connection speed.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 24),
          ReskuButton.outlined(
            label: 'Skip & Use Demo Mode',
            icon: Icons.fast_forward,
            onPressed: _enableDemoMode,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPanel() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.error_outline, color: AppColors.critical, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Initialization Failed',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyBold,
          ),
          const SizedBox(height: 8),
          const Text(
            'An error occurred while compiling WASM or downloading weights. Check your console logs, ensure WebGPU is enabled in browser flags, and retry.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 24),
          ReskuButton.primary(
            label: 'Retry Initialization',
            icon: Icons.refresh,
            onPressed: _initializeModel,
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPanel() {
    final bool isUnsupported = _modelStatus == 'Unsupported';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.psychology_alt, color: AppColors.muted, size: 48),
          const SizedBox(height: 16),
          Text(
            isUnsupported
                ? 'WebGPU Hardware Acceleration Blocked'
                : 'Local Disaster Copilot Setup',
            textAlign: TextAlign.center,
            style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            isUnsupported
                ? 'This browser does not support WebGPU. Local LLM models cannot be run hardware-accelerated. Upgrade your browser or check flags.'
                : 'Execute a conversational Qwen-1.5B model offline directly in your browser. The initial load downloads and caches weights (~1.2GB) locally.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 24),
          if (!isUnsupported) ...[
            ReskuButton.primary(
              label: _isInitializing ? 'Downloading Weights...' : 'Download & Start Copilot',
              icon: Icons.download,
              onPressed: _isInitializing ? null : _initializeModel,
            ),
            const SizedBox(height: 12),
            ReskuButton.outlined(
              label: 'Run in Demo Mode (Mock LLM)',
              icon: Icons.fast_forward,
              onPressed: _enableDemoMode,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatListPanel() {
    if (_messages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.forum_outlined, color: AppColors.muted, size: 32),
            const SizedBox(height: 12),
            const Text(
              'Local AI Disaster Copilot is active.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyBold,
            ),
            const SizedBox(height: 4),
            const Text(
              'Ask coordinator questions regarding topological partitions, centroids, or survivor medical queue updates.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 20),
            ..._suggestions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () => _sendMessage(s),
                child: Text(
                  s,
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                isUser ? 'COORDINATOR' : 'COPILOT',
                style: AppTextStyles.monospaceLabel.copyWith(fontSize: 8),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.orange.withValues(alpha: 0.1) : AppColors.grayBg,
                  border: Border.all(
                    color: isUser ? AppColors.orange : AppColors.border,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: msg['content']!.isEmpty && !isUser
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.muted,
                        ),
                      )
                    : Text(
                        msg['content']!,
                        style: AppTextStyles.bodyRegular,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.grayBg,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: !_isGenerating,
              decoration: InputDecoration(
                hintText: _isGenerating ? 'Copilot is generating response...' : 'Type query (e.g. vulnerable relays)...',
                hintStyle: const TextStyle(color: AppColors.muted, fontSize: 11),
                border: InputBorder.none,
                isDense: true,
              ),
              style: AppTextStyles.bodyRegular.copyWith(fontSize: 11),
              onSubmitted: _isGenerating ? null : _sendMessage,
            ),
          ),
          IconButton(
            icon: Icon(
              _isGenerating ? Icons.hourglass_empty : Icons.send,
              color: _isGenerating ? AppColors.muted : AppColors.orange,
              size: 16,
            ),
            onPressed: _isGenerating ? null : () => _sendMessage(_inputController.text),
          ),
        ],
      ),
    );
  }
}
