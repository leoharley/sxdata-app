import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../providers/auth_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late HistoryProvider _historyProvider;
  late AuthProvider _authProvider;
  final ScrollController _scrollController = ScrollController();

  // Mapeamento dos filtros para a API
  final Map<String, String> _filterMapping = {
    'Todos': 'all',
    'Hoje': 'today',
    'Esta Semana': 'week',
    'Pendentes': 'pending',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Aguardar o próximo frame para acessar o context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _historyProvider = context.read<HistoryProvider>();
      _authProvider = context.read<AuthProvider>();
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // Carregar mais dados quando próximo do final
      _historyProvider.loadMore(userId: _authProvider.user?.id);
    }
  }

  Future<void> _loadInitialData() async {
    await _historyProvider.loadHistory(
      userId: _authProvider.user?.id,
      refresh: true,
    );
  }

  Future<void> _onFilterChanged(String displayFilter) async {
    final apiFilter = _filterMapping[displayFilter] ?? 'all';
    await _historyProvider.setFilter(
      apiFilter,
      userId: _authProvider.user?.id,
    );
  }

  Future<void> _onRefresh() async {
    await _historyProvider.loadHistory(
      userId: _authProvider.user?.id,
      refresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header customizado com logo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(35, 52, 95, 1.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botão voltar
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  // Logo centralizado
                  Image.asset(
                    'assets/images/Logo_verde2.png',
                    width: 120,             
                    fit: BoxFit.contain,
                  ),
                  // Ícone de refresh
                  Consumer<HistoryProvider>(
                    builder: (context, historyProvider, child) {
                      return IconButton(
                        onPressed: historyProvider.isLoading ? null : _onRefresh,
                        icon: AnimatedRotation(
                          turns: historyProvider.isLoading ? 1 : 0,
                          duration: const Duration(seconds: 1),
                          child: const Icon(
                            Icons.refresh,
                            color: Color(0xFF8fae5d),
                            size: 24,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Histórico',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF23345F),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Formulários aplicados',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildFilterButtons(),
                    const SizedBox(height: 20),
                    
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: _buildFormsList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Consumer<HistoryProvider>(
      builder: (context, historyProvider, child) {
        final counters = historyProvider.counters;
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filterMapping.keys.map((displayFilter) {
              final apiFilter = _filterMapping[displayFilter]!;
              final isActive = historyProvider.selectedFilter == apiFilter;
              final count = counters[apiFilter] ?? 0;
              
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: historyProvider.isLoading ? null : () => _onFilterChanged(displayFilter),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF8fae5d) : Colors.white,
                      border: Border.all(
                        color: isActive ? const Color(0xFF8fae5d) : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      count > 0 ? '$displayFilter ($count)' : displayFilter,
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? Colors.white : Colors.grey.shade700,
                        fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFormsList() {
    return Consumer<HistoryProvider>(
      builder: (context, historyProvider, child) {
        if (historyProvider.isLoading && historyProvider.applications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8fae5d)),
                ),
                SizedBox(height: 16),
                Text(
                  'Carregando histórico...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        if (historyProvider.error != null && historyProvider.applications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  historyProvider.error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadInitialData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8fae5d),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        final applications = historyProvider.applications;
        
        if (applications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhum formulário encontrado',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Puxe para baixo para atualizar',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: applications.length + (historyProvider.isLoading && applications.isNotEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              // Mostrar indicador de carregamento no final da lista
              if (index >= applications.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8fae5d)),
                    ),
                  ),
                );
              }

              final application = applications[index];
              final isLast = index == applications.length - 1 && !historyProvider.isLoading;
              
              return _buildFormItem(application, isLast);
            },
          ),
        );
      },
    );
  }

  Widget _buildFormItem(ApplicationHistory application, bool isLast) {
    return InkWell(
      onTap: () => _showApplicationDetails(application),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(
            bottom: BorderSide(color: Color(0xFFF0F0F0)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha principal com título e status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${application.questionnaire.title} ${application.questionnaire.code}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF23345F),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${application.timing.completedAtFormatted ?? 'Data não informada'} • ${application.location.fullAddress}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (application.respondent.name?.isNotEmpty == true) ...[
                        const SizedBox(height: 3),
                        Text(
                          application.respondent.name!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusChip(application.sync),
              ],
            ),
            
            // Ícones de recursos (se houver)
            if (application.additionalData.hasPhoto || 
                application.additionalData.hasLocation || 
                application.additionalData.consentGiven) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (application.additionalData.hasPhoto)
                    _buildFeatureIcon(Icons.camera_alt, 'Foto capturada'),
                  if (application.additionalData.hasLocation)
                    _buildFeatureIcon(Icons.location_on, 'GPS capturado'),
                  if (application.additionalData.consentGiven)
                    _buildFeatureIcon(Icons.check_circle, 'Consentimento dado'),
                  if (application.timing.durationMinutes != null)
                    _buildFeatureIcon(Icons.timer, '${application.timing.durationMinutes}min'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(SyncInfo sync) {
    Color backgroundColor = _parseColor(sync.statusColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(sync.icon),
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            sync.statusLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String tooltip) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Tooltip(
        message: tooltip,
        child: Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  void _showApplicationDetails(ApplicationHistory application) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetailsBottomSheet(application),
    );
  }

  Widget _buildDetailsBottomSheet(ApplicationHistory application) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Detalhes da Aplicação',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF23345F),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Conteúdo
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Questionário
                  _buildDetailSection(
                    'Questionário',
                    '${application.questionnaire.title} ${application.questionnaire.code}',
                    Icons.assignment,
                  ),
                  
                  // Respondente
                  if (application.respondent.name?.isNotEmpty == true)
                    _buildDetailSection(
                      'Respondente',
                      application.respondent.name!,
                      Icons.person,
                    ),
                  
                  // Data e hora
                  _buildDetailSection(
                    'Data e Hora',
                    '${application.timing.completedAtFormatted}\n${application.timing.timeAgo}',
                    Icons.schedule,
                  ),
                  
                  // Localização
                  _buildDetailSection(
                    'Localização',
                    application.location.fullAddress,
                    Icons.location_on,
                  ),
                  
                  // Status
                  _buildDetailSection(
                    'Status de Sincronização',
                    application.sync.statusLabel,
                    _getStatusIcon(application.sync.icon),
                    statusColor: _parseColor(application.sync.statusColor),
                  ),
                  
                  // Informações adicionais
                  const SizedBox(height: 20),
                  const Text(
                    'Recursos Utilizados',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF23345F),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      _buildResourceChip(
                        'Foto',
                        application.additionalData.hasPhoto,
                        Icons.camera_alt,
                      ),
                      const SizedBox(width: 8),
                      _buildResourceChip(
                        'GPS',
                        application.additionalData.hasLocation,
                        Icons.location_on,
                      ),
                      const SizedBox(width: 8),
                      _buildResourceChip(
                        'Consentimento',
                        application.additionalData.consentGiven,
                        Icons.check_circle,
                      ),
                    ],
                  ),
                  
                  if (application.timing.durationMinutes != null) ...[
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      'Duração',
                      '${application.timing.durationMinutes} minutos',
                      Icons.timer,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor?.withOpacity(0.1) ?? const Color(0xFF8fae5d).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: statusColor ?? const Color(0xFF8fae5d),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF23345F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceChip(String label, bool isActive, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF8fae5d).withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFF8fae5d) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isActive ? const Color(0xFF8fae5d) : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? const Color(0xFF8fae5d) : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String iconName) {
    switch (iconName) {
      case 'check_circle':
        return Icons.check_circle;
      case 'sync':
        return Icons.sync;
      case 'error':
        return Icons.error;
      default:
        return Icons.sync;
    }
  }

  Color _parseColor(String colorString) {
    try {
      // Remove o # se presente e converte para Color
      final hexColor = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      // Fallback para cores padrão
      switch (colorString.toLowerCase()) {
        case 'green':
        case '#4caf50':
          return const Color(0xFF4CAF50);
        case 'orange':
        case '#ff9800':
          return Colors.orange.shade700;
        case 'red':
        case '#f44336':
          return const Color(0xFFF44336);
        case 'blue':
        case '#2196f3':
          return const Color(0xFF2196F3);
        default:
          return Colors.grey;
      }
    }
  }
}