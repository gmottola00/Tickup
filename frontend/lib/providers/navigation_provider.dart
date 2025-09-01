import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider per nascondere/mostrare la bottom navigation
final hideBottomNavProvider = StateProvider<bool>((ref) => false);

// Provider per tracciare la tab corrente
final currentTabIndexProvider = StateProvider<int>((ref) => 0);
