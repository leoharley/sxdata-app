import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../models/questionnaire.dart';
import '../providers/form_provider.dart';
import 'form_completed_screen.dart';

class PhotoCaptureScreen extends StatefulWidget {
  final Questionnaire questionnaire;

  const PhotoCaptureScreen({super.key, required this.questionnaire});

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  File? _capturedPhoto;
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isNavigating = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    print('📸 PhotoCaptureScreen iniciado');
    print('📋 Questionnaire: ${widget.questionnaire.title}');
    print('📍 Requer localização: ${widget.questionnaire.requiresLocation}');
    print('📸 Requer foto: ${widget.questionnaire.requiresPhoto}');
    
    if (widget.questionnaire.requiresLocation) {
      _getCurrentLocation();
    }
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
                  // Ícone de câmera
                  const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF8fae5d),
                    size: 24,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const Text(
                              'Evidência Fotográfica',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF23345F),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.questionnaire.requiresPhoto 
                                  ? 'Adicione uma foto para validar a coleta'
                                  : 'Foto opcional para evidência',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                            
                            _buildPhotoCapture(),
                            
                            if (_capturedPhoto != null) ...[
                              const SizedBox(height: 20),
                              _buildCapturedPhoto(),
                            ],
                            
                            if (widget.questionnaire.requiresLocation) ...[
                              const SizedBox(height: 20),
                              _buildLocationSection(),
                            ],
                          ],
                        ),
                      ),
                    ),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCapture() {
    return GestureDetector(
      onTap: _capturePhoto,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF8fae5d),
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFF8FAF6),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt,
                size: 60,
                color: Color(0xFF8fae5d),
              ),
              SizedBox(height: 15),
              Text(
                'Toque para capturar foto',
                style: TextStyle(
                  color: Color(0xFF8fae5d),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'A foto será anexada ao formulário automaticamente',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapturedPhoto() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF8fae5d), size: 20),
              SizedBox(width: 8),
              Text(
                '📋 Foto capturada:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF23345F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: FileImage(_capturedPhoto!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg • ${(_capturedPhoto!.lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    if (_isLoadingLocation) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text(
              'Obtendo localização...',
              style: TextStyle(color: Colors.blue),
            ),
          ],
        ),
      );
    }

    if (_currentPosition != null) {
      return _buildLocationInfo();
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.location_off,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(height: 5),
          const Text(
            'Localização não disponível',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Verifique as permissões de localização',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _getCurrentLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFe3f2fd),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.location_on,
            color: Color(0xFF1976d2),
            size: 24,
          ),
          const SizedBox(height: 5),
          const Text(
            'Coordenadas registradas',
            style: TextStyle(
              color: Color(0xFF1976d2),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final canFinish = !widget.questionnaire.requiresPhoto || _capturedPhoto != null;
    
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          if (_capturedPhoto != null)
            Expanded(
              child: OutlinedButton(
                onPressed: _isNavigating ? null : _retakePhoto,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Text(
                  'Refazer Foto',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          
          if (_capturedPhoto != null) const SizedBox(width: 10),
          
          Expanded(
            flex: _capturedPhoto != null ? 2 : 1,
            child: ElevatedButton(
              //onPressed: _isNavigating ? null : (canFinish ? _completeForm : null),
              onPressed: _completeForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: canFinish ? const Color(0xFF8fae5d) : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isNavigating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Finalizar',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Substitua o método _capturePhoto na photo_capture_screen.dart:

  Future<void> _capturePhoto() async {
    print('📸 Tentando capturar foto');
    
    try {
      final permission = await Permission.camera.request();
      print('📸 Permissão de câmera: $permission');
      
      if (permission.isGranted) {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
        
        if (photo != null) {
          print('📸 Foto capturada: ${photo.path}');
          setState(() {
            _capturedPhoto = File(photo.path);
          });
          
          try {
            final formProvider = Provider.of<FormProvider>(context, listen: false);
            
            // NOVA LÓGICA: Não salvar imediatamente offline aqui
            // Apenas definir o caminho da foto no formulário
            formProvider.setPhoto(photo.path);
            print('✅ Caminho da foto definido no FormProvider');
            
            // A foto será salva offline automaticamente durante a submissão do formulário
            
          } catch (e) {
            print('❌ Erro ao definir foto no FormProvider: $e');
          }
        } else {
          print('⚠️ Nenhuma foto foi capturada');
        }
      } else {
        print('❌ Permissão de câmera negada');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permissão de câmera necessária para capturar foto'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao capturar foto: $e');
      print('📋 Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao capturar foto: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _retakePhoto() {
    print('🔄 Refazendo foto');
    setState(() {
      _capturedPhoto = null;
    });
  }

  Future<void> _getCurrentLocation() async {
    print('📍 Tentando obter localização');
    
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final permission = await Permission.location.request();
      print('📍 Permissão de localização: $permission');
      
      if (permission.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        print('📍 Localização obtida: ${position.latitude}, ${position.longitude}');
        
        setState(() {
          _currentPosition = position;
        });
        
        try {
          final formProvider = Provider.of<FormProvider>(context, listen: false);
          formProvider.setLocation(
            position.latitude, 
            position.longitude, 
            ''
          );
          print('✅ Localização salva no FormProvider');
        } catch (e) {
          print('❌ Erro ao salvar localização no FormProvider: $e');
        }
      } else {
        print('❌ Permissão de localização negada');
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao obter localização: $e');
      print('📋 Stack trace: $stackTrace');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _completeForm() {
    print('🏁 Finalizando formulário');
    
    if (_isNavigating) {
      print('⚠️ Já está navegando, ignorando');
      return;
    }
    
    // Verificar se foto é obrigatória
   /* if (widget.questionnaire.requiresPhoto && _capturedPhoto == null) {
      print('❌ Foto obrigatória não capturada');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto é obrigatória para este questionário'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    } */
    
    setState(() {
      _isNavigating = true;
    });
    
    try {
      // Debug do FormProvider antes de navegar
      final formProvider = Provider.of<FormProvider>(context, listen: false);
      formProvider.debugPrintCurrentState();
      
      print('🔄 Navegando para FormCompletedScreen');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FormCompletedScreen(
            questionnaire: widget.questionnaire,
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('❌ Erro ao navegar para tela de conclusão: $e');
      print('📋 Stack trace: $stackTrace');
      
      setState(() {
        _isNavigating = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao finalizar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}