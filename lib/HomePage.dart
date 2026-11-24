import 'dart:async';
import 'package:flutter/material.dart';
import 'package:proyecto/UserPage.dart';
import 'package:proyecto/LoginPage.dart';
import 'package:proyecto/LocationPage.dart';
import 'package:proyecto/services/notification_service.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _vasosTomados = 0;
  final int _metaVasos = 8;
  bool _notificacionesActivas = false;

  void _registrarVasoAgua() {
    if (_vasosTomados < _metaVasos) {
      setState(() {
        _vasosTomados++;
      });
    }
  }

  // Control del switch: Pide permisos al activar, desactiva y cancela al apagar
  Future<void> _toggleNotificaciones(bool valor) async {
    if (valor) {
      // El usuario movió el switch para activar -> Pedimos permiso en este momento
      bool permisoConcedido = await NotificationService.pedirPermisos();
      if (permisoConcedido) {
        await NotificationService.programarNotificacionAgua();
        setState(() {
          _notificacionesActivas = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notificaciones activadas (cada 1 minuto)'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Si denegó el permiso, el switch se queda apagado
        setState(() {
          _notificacionesActivas = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permiso de notificaciones denegado'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      // El usuario desactivó el switch -> Cancelamos notificaciones
      await NotificationService.cancelarNotificaciones();
      setState(() {
        _notificacionesActivas = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificaciones desactivadas'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'SiGeUL - Home',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.onSurface,
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: colorScheme.primary,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.school_rounded,
                        size: 36,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'SiGeUL',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.group_rounded, color: colorScheme.primary),
                    ),
                    title: const Text(
                      'Usuarios',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: const Text('Gestión de cuentas'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Userpage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.map_rounded, color: colorScheme.primary),
                    ),
                    title: const Text(
                      'Ubicaciones GPS',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: const Text('Historial y Google Maps'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LocationPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.logout_rounded, color: Colors.red),
                  ),
                  title: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                          (route) => false,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Control de toma de agua e interruptor de notificaciones
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.secondary.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.water_drop_rounded, color: colorScheme.secondary),
                          const SizedBox(width: 8),
                          const Text(
                            'Control de Hidratación',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Text(
                        '$_vasosTomados / $_metaVasos vasos',
                        style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _vasosTomados / _metaVasos,
                      backgroundColor: colorScheme.secondary.withOpacity(0.1),
                      color: colorScheme.secondary,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Meta diaria recomendada',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.secondary.withOpacity(0.1),
                          foregroundColor: colorScheme.secondary,
                        ),
                        icon: const Icon(Icons.add_rounded),
                        onPressed: _registrarVasoAgua,
                        tooltip: 'Registrar vaso de agua',
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // Interruptor que solicita permisos al activarse y cancela al apagarse
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Recordatorios automáticos',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Recibir alerta cada 1 minuto',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    activeColor: colorScheme.secondary,
                    value: _notificacionesActivas,
                    onChanged: _toggleNotificaciones,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}