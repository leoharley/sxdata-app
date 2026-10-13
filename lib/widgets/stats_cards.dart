import 'package:flutter/material.dart';
import '../models/questionnaire.dart';

class StatsCards extends StatelessWidget {
  final List<Questionnaire> questionnaires;
  
  const StatsCards({
    super.key,
    required this.questionnaires,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            _getQuestionnairesTodayCount().toString(),
            'Formulários Disponibilizados Hoje',
            const Color(0xFF8FAE5D),
          ),
        ),
        /*const SizedBox(width: 15),
        Expanded(
          child: _buildStatCard(
            _getPendingSyncCount().toString(),
            'Pendentes de Sincronizar',
            Colors.orange,
          ),
        ), */
      ],
    );
  }

  /// Conta quantos questionários foram criados hoje
  int _getQuestionnairesTodayCount() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return questionnaires.where((questionnaire) {
      final createdDate = DateTime(
        questionnaire.createdAt.year,
        questionnaire.createdAt.month,
        questionnaire.createdAt.day,
      );
      return createdDate.isAtSameMomentAs(today) || 
             (createdDate.isAfter(today) && createdDate.isBefore(tomorrow));
    }).length;
  }

  Widget _buildStatCard(String number, String label, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF23345F),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}