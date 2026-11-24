import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:proyecto/RegisterPage.dart';
import 'package:proyecto/database.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:quickalert/quickalert.dart';
import 'package:proyecto/services/camera_service.dart';

class Userpage extends StatefulWidget {
  const Userpage({super.key});

  @override
  State<Userpage> createState() => _UserpageState();
}

class _UserpageState extends State<Userpage> {
  late Future<List<Map<String, dynamic>>> _users;
  final ImagePicker _picker = ImagePicker();

  Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
    final db = await DatabaseHelper.database;
    return await db.query('users');
  }

  Future<void> _actualizarUsuarios() async {
    setState(() {
      _users = obtenerUsuarios();
    });
  }

  @override
  void initState() {
    super.initState();
    _actualizarUsuarios();
    _checkLostData();
  }

  Future<void> _checkLostData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty || response.file == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(response.file!.path);
      await File(response.file!.path).copy('${appDir.path}/$fileName');

      _actualizarUsuarios();
    } catch (e) {
      debugPrint('Error recuperando datos: $e');
    }
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

  void _confirmarYEditar(Map<String, dynamic> usuario) {
    final colorScheme = Theme.of(context).colorScheme;

    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: 'Editar Usuario',
      text: '¿Deseas modificar los datos de ${usuario['name']}?',
      confirmBtnText: 'SÍ',
      cancelBtnText: 'NO',
      confirmBtnColor: colorScheme.primary,
      onCancelBtnTap: () => Navigator.of(context, rootNavigator: true).pop(),
      onConfirmBtnTap: () {
        Navigator.of(context, rootNavigator: true).pop();
        _mostrarDialogoEditar(usuario);
      },
    );
  }

  void _mostrarDialogoEditar(Map<String, dynamic> usuario) {
    final nameController = TextEditingController(text: usuario['name']);
    final passwordController = TextEditingController(text: usuario['password'] ?? '');

    File? tempImageFile = usuario['image_path'] != null && usuario['image_path'].isNotEmpty
        ? File(usuario['image_path'])
        : null;

    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void showImageSourceModal() {
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
                        'Actualizar foto de perfil',
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
                                setStateDialog(() {
                                  tempImageFile = File(imagePath);
                                });
                              }
                            }
                          } catch (e) {
                            debugPrint('Error abriendo cámara: $e');
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
                            setStateDialog(() {
                              tempImageFile = File(path);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.edit_rounded, color: colorScheme.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Actualizar Perfil',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close_rounded, color: Colors.grey),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.25),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor: colorScheme.primary.withOpacity(0.12),
                                backgroundImage: tempImageFile != null && tempImageFile!.existsSync()
                                    ? FileImage(tempImageFile!)
                                    : null,
                                child: tempImageFile == null || !tempImageFile!.existsSync()
                                    ? Icon(Icons.person_rounded, size: 48, color: colorScheme.primary)
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Material(
                                color: colorScheme.primary,
                                shape: const CircleBorder(),
                                elevation: 4,
                                child: InkWell(
                                  onTap: showImageSourceModal,
                                  customBorder: const CircleBorder(),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre completo',
                          labelStyle: TextStyle(color: Colors.grey.shade600),
                          prefixIcon: Icon(Icons.badge_outlined, color: colorScheme.primary),
                          filled: true,
                          fillColor: colorScheme.primary.withOpacity(0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          labelStyle: TextStyle(color: Colors.grey.shade600),
                          prefixIcon: Icon(Icons.lock_outline, color: colorScheme.primary),
                          filled: true,
                          fillColor: colorScheme.primary.withOpacity(0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                final db = await DatabaseHelper.database;
                                await db.update(
                                  'users',
                                  {
                                    'name': nameController.text.trim(),
                                    'password': passwordController.text.trim(),
                                    'image_path': tempImageFile?.path ?? '',
                                  },
                                  where: 'user = ?',
                                  whereArgs: [usuario['user']],
                                );

                                if (mounted) Navigator.pop(dialogContext);
                                _actualizarUsuarios();
                              },
                              child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Gestión de Usuarios', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.onSurface,
        centerTitle: true,
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.45),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Registerpage()),
            );
            _actualizarUsuarios();
          },
          backgroundColor: colorScheme.primary,
          elevation: 0,
          child: const Icon(Icons.person_add_rounded, color: Colors.white),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _users,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          }

          final users = snapshot.data ?? [];

          return RefreshIndicator(
            color: colorScheme.primary,
            onRefresh: _actualizarUsuarios,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Perfiles Registrados',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.group_rounded, size: 14, color: colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                '${users.length}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                users.isEmpty
                    ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_off_rounded, size: 70, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No hay usuarios registrados\n(Desliza hacia abajo para actualizar)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                )
                    : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final usuario = users[index];
                        final nombre = usuario['name'] ?? '';
                        final imagePath = usuario['image_path'] ?? '';
                        final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Slidable(
                            key: ValueKey(usuario['user']),
                            startActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              children: [
                                // Usamos un CustomPaint o Container con margen interno para separar visualmente el botón
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    child: SlidableAction(
                                      onPressed: (slidableContext) {
                                        QuickAlert.show(
                                          context: context,
                                          type: QuickAlertType.confirm,
                                          title: 'Eliminar Usuario',
                                          text: '¿Quieres eliminar a este usuario?',
                                          confirmBtnText: 'SÍ',
                                          cancelBtnText: 'NO',
                                          confirmBtnColor: const Color(0xFFFE4A49),
                                          onCancelBtnTap: () => Navigator.of(context, rootNavigator: true).pop(),
                                          onConfirmBtnTap: () async {
                                            Navigator.of(context, rootNavigator: true).pop();
                                            final db = await DatabaseHelper.database;
                                            await db.delete('users', where: 'user = ?', whereArgs: [usuario['user']]);
                                            _actualizarUsuarios();
                                          },
                                        );
                                      },
                                      backgroundColor: const Color(0xFFFE4A49),
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete_outline_rounded,
                                      label: 'Eliminar',
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            endActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              children: [
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    child: SlidableAction(
                                      flex: 2,
                                      onPressed: (context) => _confirmarYEditar(usuario),
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      icon: Icons.edit_outlined,
                                      label: 'Editar',
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.primary.withOpacity(0.35),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: colorScheme.primary.withOpacity(0.15),
                                  backgroundImage: imagePath.isNotEmpty && File(imagePath).existsSync()
                                      ? FileImage(File(imagePath))
                                      : null,
                                  child: imagePath.isEmpty || !File(imagePath).existsSync()
                                      ? Text(
                                    inicial,
                                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
                                  )
                                      : null,
                                ),
                                title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text('@${usuario['user']}', style: TextStyle(color: Colors.grey.shade600)),
                                ),
                                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: users.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}