import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:proyecto/database.dart';
import 'package:proyecto/services/camera_service.dart';
import 'package:quickalert/quickalert.dart';

class Registerpage extends StatefulWidget {
  const Registerpage({super.key});

  @override
  State<Registerpage> createState() => _RegisterpageState();
}

class _RegisterpageState extends State<Registerpage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  bool _nameHasError = false;
  bool _userHasError = false;
  bool _passHasError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String?> _pickFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = p.basename(pickedFile.path);
        final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
        return savedImage.path;
      }
    } catch (e) {
      debugPrint('Error al seleccionar de galería: $e');
    }
    return null;
  }

  void _showImageSourceModal(BuildContext context, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Seleccionar foto de perfil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: CircleAvatar(
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                child: Icon(Icons.camera_alt_rounded, color: colorScheme.primary),
              ),
              title: const Text('Tomar una foto', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final cameras = await availableCameras();
                  if (cameras.isNotEmpty) {
                    final String? imagePath = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CameraScreen(camera: cameras.first),
                      ),
                    );
                    if (imagePath != null && imagePath.isNotEmpty) {
                      setState(() {
                        _imageFile = File(imagePath);
                      });
                    }
                  }
                } catch (e) {
                  debugPrint('Error abriendo la cámara: $e');
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: CircleAvatar(
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                child: Icon(Icons.photo_library_rounded, color: colorScheme.primary),
              ),
              title: const Text('Elegir de la galería', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                final path = await _pickFromGallery();
                if (path != null) {
                  setState(() {
                    _imageFile = File(path);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registerUser() async {
    setState(() {
      _nameHasError = _nameController.text.trim().isEmpty;
      _userHasError = _userController.text.trim().isEmpty;
      _passHasError = _passwordController.text.trim().isEmpty;
    });

    if (_formKey.currentState!.validate()) {
      final db = await DatabaseHelper.database;

      final existingUser = await db.query(
        'users',
        where: 'user = ?',
        whereArgs: [_userController.text.trim()],
      );

      if (existingUser.isNotEmpty) {
        if (!mounted) return;
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Usuario Existente',
          text: 'El nombre de usuario ya está registrado en el sistema.',
          confirmBtnText: 'ENTENDIDO',
          confirmBtnColor: const Color(0xFFFE4A49),
        );
        return;
      }

      await db.insert('users', {
        'user': _userController.text.trim(),
        'name': _nameController.text.trim(),
        'password': _passwordController.text.trim(),
        'image_path': _imageFile?.path ?? '',
      });

      if (!mounted) return;

      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: '¡Registro Exitoso!',
        text: 'La cuenta se ha creado correctamente.',
        confirmBtnText: 'ACEPTAR',
        confirmBtnColor: Theme.of(context).colorScheme.primary,
        onConfirmBtnTap: () {
          Navigator.of(context, rootNavigator: true).pop();
          Navigator.pop(context);
        },
      );
    }
  }

  InputDecoration _buildInputDecoration({
    required ColorScheme colorScheme,
    required Color errorColor,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    required bool hasError,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: Colors.grey.shade700),
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(
        prefixIcon,
        color: hasError ? errorColor : colorScheme.primary,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
      errorStyle: TextStyle(color: errorColor, fontWeight: FontWeight.w500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const errorColor = Color(0xFFE57373);
    final hasImage = _imageFile != null && _imageFile!.existsSync();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 62,
                                backgroundColor: Colors.grey.shade100,
                                backgroundImage: hasImage ? FileImage(_imageFile!) : null,
                                child: !hasImage
                                    ? Icon(
                                  Icons.person_add_alt_1_rounded,
                                  size: 52,
                                  color: colorScheme.primary,
                                )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () => _showImageSourceModal(context, colorScheme),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Crear Cuenta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Regístrate para comenzar en SiGeUL',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 36),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        onChanged: (value) {
                          if (_nameHasError) {
                            setState(() => _nameHasError = value.trim().isEmpty);
                          }
                        },
                        decoration: _buildInputDecoration(
                          colorScheme: colorScheme,
                          errorColor: errorColor,
                          labelText: 'Nombre Completo',
                          hintText: 'Ingresa tu nombre completo',
                          prefixIcon: Icons.badge_outlined,
                          hasError: _nameHasError,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            setState(() => _nameHasError = true);
                            return 'Ingresa tu nombre completo';
                          }
                          setState(() => _nameHasError = false);
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _userController,
                        textInputAction: TextInputAction.next,
                        onChanged: (value) {
                          if (_userHasError) {
                            setState(() => _userHasError = value.trim().isEmpty);
                          }
                        },
                        decoration: _buildInputDecoration(
                          colorScheme: colorScheme,
                          errorColor: errorColor,
                          labelText: 'Usuario',
                          hintText: 'Ingresa tu usuario',
                          prefixIcon: Icons.person_outline_rounded,
                          hasError: _userHasError,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            setState(() => _userHasError = true);
                            return 'Ingresa un nombre de usuario';
                          }
                          setState(() => _userHasError = false);
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onChanged: (value) {
                          if (_passHasError) {
                            setState(() => _passHasError = value.trim().isEmpty);
                          }
                        },
                        decoration: _buildInputDecoration(
                          colorScheme: colorScheme,
                          errorColor: errorColor,
                          labelText: 'Contraseña',
                          hintText: 'Ingresa tu contraseña',
                          prefixIcon: Icons.lock_outline_rounded,
                          hasError: _passHasError,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _obscurePassword ? Colors.grey.shade500 : colorScheme.primary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            setState(() => _passHasError = true);
                            return 'Ingresa tu contraseña';
                          }
                          setState(() => _passHasError = false);
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _registerUser,
                          child: const Text(
                            'Registrar Cuenta',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 12,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.grey.shade800,
                ),
                tooltip: 'Regresar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}