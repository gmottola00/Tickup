import 'package:flutter/material.dart';
import 'package:tickup/core/network/dio_client.dart';

class PoolsScreen extends StatefulWidget {
  const PoolsScreen({super.key});

  @override
  State<PoolsScreen> createState() => _PoolsScreenState();
}

class _PoolsScreenState extends State<PoolsScreen> {
  List<dynamic> pools = [];

  @override
  void initState() {
    super.initState();
    fetchPools();
  }

  Future<void> fetchPools() async {
    final response = await DioClient().get('/pools');
    setState(() {
      pools = response.data ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pools')),
      body: ListView.builder(
        itemCount: pools.length,
        itemBuilder: (context, index) {
          final pool = pools[index];
          return ListTile(
            title: Text(pool.toString()),
          );
        },
      ),
    );
  }
}
