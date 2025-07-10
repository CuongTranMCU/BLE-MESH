import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../cloud_services/rtdb_service_ble.dart';
import '../../../../themes/mycolors.dart';

class SelectNode extends StatefulWidget {
  const SelectNode({super.key, required this.floorNumber, required this.isInFloorInfo});

  final String floorNumber;
  final bool isInFloorInfo;
  @override
  State<SelectNode> createState() => _SelectNodeState();
}

class _SelectNodeState extends State<SelectNode> {
  final _selectNodeController = SelectNodeController();
  final _dataStreamPublisher = RTDBServiceBLE();
  StreamSubscription<Map<String, dynamic>>? _floorSubscription;
  Map<String, dynamic> _floorData = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _floorSubscription = _dataStreamPublisher.getListFloor().listen(
      (data) {
        if (data != _floorData && mounted) {
          setState(() => _floorData = data);
        }
      },
      onError: (error) => debugPrint("Floor data stream error: $error"),
    );
  }

  @override
  void dispose() {
    _floorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return (_isLoading)
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            appBar: AppBar(
              title: const Text(
                "List of nodes",
                style: TextStyle(color: AppTitleColor2, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              leading: IconButton(
                color: AppTitleColor2,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Column(
              children: [
                Text(
                  "Current Floor : ${widget.floorNumber}",
                  style: const TextStyle(color: AppTitleColor1, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SelectNodeProvider(
                    controller: _selectNodeController,
                    child: SelectNodeView(floorData: _floorData),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(200, 50),
                    backgroundColor: ButtonColor01,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _buttonClick,
                  child: const Text("OK", style: TextStyle(color: TextColor02, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
  }

  Future<void> _buttonClick() async {
    final Set<String> selectedNodes = _selectNodeController.selectedNodes;

    if (selectedNodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one node")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy giá trị từ _floorData
      final floorDataForNumber = _floorData[widget.floorNumber];

      // Kiểm tra và lấy length an toàn
      int floorLength = 0;
      if (floorDataForNumber != null) {
        if (floorDataForNumber is List || floorDataForNumber is Map) {
          floorLength = floorDataForNumber.length;
        } else {
          debugPrint("Unexpected type for floorData[${widget.floorNumber}]: $floorDataForNumber");
        }
      } else {
        debugPrint("_floorData[${widget.floorNumber}] is null");
      }

      await _dataStreamPublisher.updateFloor(
        floorNumber: widget.floorNumber,
        nodes: selectedNodes.toList(),
        length: floorLength,
      );

      if (mounted) {
        if (widget.isInFloorInfo) {
          Navigator.pop(context);
        } else {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error creating floor: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class SelectNodeView extends StatelessWidget {
  SelectNodeView({super.key, required this.floorData});
  final Map<String, dynamic> floorData;

  Widget _buildMessage(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataStreamPublisher = RTDBServiceBLE();

    return StreamBuilder<List<String>>(
      stream: dataStreamPublisher.getLatestNodeList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildMessage('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildMessage('No data available');
        }

        // Filter out nodes that are already assigned to floors
        List<String> data = _filterAvailableNodes(snapshot.data!);
        //debugPrint("Final Data : $data");
        if (data.isEmpty) {
          return _buildMessage('All nodes are already assigned to floors');
        } else {
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final node = data[index];
              return _NodeListTile(node: node);
            },
          );
        }
      },
    );
  }

  List<String> _filterAvailableNodes(List<String> allNodes) {
    final Set<String> availableNodesSet = Set<String>.from(allNodes);
    final Set<String> assignedNodes = {};

    //debugPrint("Floor Data : $floorData");

    // Collect all assigned nodes from floor data
    floorData.forEach((key, value) {
      if (value is Map) {
        // If value is a Map, use .values
        assignedNodes.addAll(value.values.cast<String>());
      } else if (value is Iterable) {
        // If value is a List or JSArray, treat it as an iterable
        assignedNodes.addAll(value.cast<String>());
      } else {
        //debugPrint("Unexpected floorData value type: $value");
      }
    });

    // Remove assigned nodes from available nodes
    return availableNodesSet.difference(assignedNodes).toList();
  }
}

class _NodeListTile extends StatelessWidget {
  final String node;

  const _NodeListTile({required this.node});

  @override
  Widget build(BuildContext context) {
    final controller = SelectNodeProvider.of(context);
    final isSelected = controller.isSelected(node);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade50,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Image.asset(
          "assets/icons/node.png",
          width: 32,
          height: 32,
          color: Colors.blue,
        ),
        title: Text(node),
        titleTextStyle: const TextStyle(
          color: TextColor04,
          fontSize: 20,
          fontWeight: FontWeight.normal,
        ),
        trailing: Icon(
          isSelected ? Icons.circle_rounded : Icons.circle_outlined,
          color: IconColor02,
        ),
        onTap: () => controller.toggleSelection(node),
      ),
    );
  }
}

class SelectNodeProvider extends InheritedNotifier<SelectNodeController> {
  const SelectNodeProvider({
    super.key,
    required SelectNodeController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static SelectNodeController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SelectNodeProvider>()?.notifier ?? (throw FlutterError('SelectNodeProvider not found in context'));
  }
}

class SelectNodeController extends ChangeNotifier {
  final Set<String> _selectedNodes = {};

  bool isSelected(String node) => _selectedNodes.contains(node);
  Set<String> get selectedNodes => Set.unmodifiable(_selectedNodes);

  void toggleSelection(String node) {
    if (_selectedNodes.contains(node)) {
      _selectedNodes.remove(node);
    } else {
      _selectedNodes.add(node);
    }
    notifyListeners();
  }
}
