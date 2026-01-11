import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/module_model.dart';
import '../../core/models/topic_model.dart';
import '../../providers/course_provider.dart';

class ManageSyllabusScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const ManageSyllabusScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<ManageSyllabusScreen> createState() => _ManageSyllabusScreenState();
}

class _ManageSyllabusScreenState extends State<ManageSyllabusScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch modules when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().fetchModulesForCourse(widget.courseId);
    });
  }

  // Helper to show Add/Edit Module Dialog
  void _showModuleDialog({Module? existingModule}) {
    final nameCtrl = TextEditingController(text: existingModule?.name ?? '');
    final descCtrl = TextEditingController(
      text: existingModule?.description ?? '',
    );
    final hoursCtrl = TextEditingController(
      text: existingModule?.estimatedHours.toString() ?? '10',
    );
    final skillsCtrl = TextEditingController(
      text: existingModule?.skillsMapped.join(',') ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingModule == null ? "Add Module" : "Edit Module"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Module Name"),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: hoursCtrl,
                decoration: const InputDecoration(labelText: "Est. Hours"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: skillsCtrl,
                decoration: const InputDecoration(
                  labelText: "Skills (comma separated)",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newModule = Module(
                id: existingModule?.id ?? '', // ID handled by backend on create
                courseId: widget.courseId,
                name: nameCtrl.text,
                description: descCtrl.text,
                sequenceOrder:
                    existingModule?.sequenceOrder ??
                    (context.read<CourseProvider>().currentModules.length + 1),
                estimatedHours: int.tryParse(hoursCtrl.text) ?? 0,
                skillsMapped: skillsCtrl.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
              );

              // Currently only implementing CREATE in provider example
              // Ideally update updateModule in provider too
              if (existingModule == null) {
                await context.read<CourseProvider>().createModule(newModule);
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // Helper to show Add/Edit Topic Dialog
  void _showTopicDialog(String moduleId, {Topic? existingTopic}) {
    final nameCtrl = TextEditingController(text: existingTopic?.name ?? '');
    final descCtrl = TextEditingController(
      text: existingTopic?.description ?? '',
    );
    final durationCtrl = TextEditingController(
      text: existingTopic?.estimatedDurationMinutes.toString() ?? '60',
    );
    final skillsCtrl = TextEditingController(
      text: existingTopic?.skillsMapped.join(',') ?? '',
    );
    String bloomLevel = existingTopic?.bloomLevel ?? 'application';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingTopic == null ? "Add Topic" : "Edit Topic"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Topic Name"),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: durationCtrl,
                decoration: const InputDecoration(labelText: "Duration (mins)"),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                value: bloomLevel,
                decoration: const InputDecoration(
                  labelText: "Bloom Taxonomy Level",
                ),
                items:
                    [
                          'knowledge',
                          'comprehension',
                          'application',
                          'analysis',
                          'synthesis',
                          'evaluation',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (v) => bloomLevel = v!,
              ),
              TextField(
                controller: skillsCtrl,
                decoration: const InputDecoration(
                  labelText: "Skills (comma separated)",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTopic = Topic(
                id: existingTopic?.id ?? '',
                moduleId: moduleId,
                name: nameCtrl.text,
                description: descCtrl.text,
                sequenceOrder: 1, // Logic for order needed
                estimatedDurationMinutes: int.tryParse(durationCtrl.text) ?? 60,
                difficultyLevel: 'intermediate',
                bloomLevel: bloomLevel,
                skillsMapped: skillsCtrl.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
              );

              await context.read<CourseProvider>().createTopic(newTopic);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final modules = provider.currentModules;

    return Scaffold(
      backgroundColor:
          AppColors.background, // Ensure AppColors matches your theme
      appBar: AppBar(
        title: Text("Syllabus: ${widget.courseName}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchModulesForCourse(widget.courseId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showModuleDialog(),
        label: const Text("Add Module"),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : modules.isEmpty
          ? const Center(
              child: Text(
                "No modules found. Add one to get started!",
                style: TextStyle(color: Colors.white),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                final module = modules[index];
                return _ModuleTile(
                  module: module,
                  onAddTopic: () => _showTopicDialog(module.id),
                );
              },
            ),
    );
  }
}

class _ModuleTile extends StatefulWidget {
  final Module module;
  final VoidCallback onAddTopic;

  const _ModuleTile({required this.module, required this.onAddTopic});

  @override
  State<_ModuleTile> createState() => _ModuleTileState();
}

class _ModuleTileState extends State<_ModuleTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final topics = provider.getTopicsForModule(widget.module.id);

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.module.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              "${widget.module.estimatedHours} Hours • ${widget.module.skillsMapped.length} Skills",
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: IconButton(
              icon: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() => _expanded = !_expanded);
                if (_expanded && topics.isEmpty) {
                  provider.fetchTopicsForModule(widget.module.id);
                }
              },
            ),
          ),
          if (_expanded) ...[
            const Divider(color: Colors.grey),
            if (topics.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: provider.isLoading
                    ? const CircularProgressIndicator() // Note: global loading might obscure this local loading
                    : const Text(
                        "No topics yet.",
                        style: TextStyle(color: Colors.grey),
                      ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topics.length,
                itemBuilder: (ctx, i) => ListTile(
                  leading: const Icon(
                    Icons.topic_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  title: Text(
                    topics[i].name,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  subtitle: Text(
                    topics[i].bloomLevel,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton.icon(
                onPressed: widget.onAddTopic,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("Add Topic"),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
