
import 'package:flutter/material.dart';

void main() {
  runApp(const TrustPayApp());
}

const teal = Color(0xFF008C82);
const dark = Color(0xFF14252B);
const bg = Color(0xFFF6F8F8);

class TrustPayApp extends StatelessWidget {
  const TrustPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrustPay AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: teal,
          primary: teal,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: dark,
          centerTitle: false,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class Milestone {
  String title;
  int amount;
  bool completed;

  Milestone({
    required this.title,
    required this.amount,
    this.completed = false,
  });
}

class Project {
  String title;
  String description;
  List<Milestone> milestones;

  Project({
    required this.title,
    required this.description,
    required this.milestones,
  });

  int get total =>
      milestones.fold(0, (sum, m) => sum + m.amount);

  int get completedCount =>
      milestones.where((m) => m.completed).length;

  double get progress => milestones.isEmpty
      ? 0
      : completedCount / milestones.length;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Project> projects = [
    Project(
      title: 'E-Commerce Website',
      description: 'Responsive online shopping platform',
      milestones: [
        Milestone(title: 'UI Design', amount: 200, completed: true),
        Milestone(title: 'Frontend Development', amount: 300),
        Milestone(title: 'Backend Integration', amount: 350),
        Milestone(title: 'Testing & Delivery', amount: 150),
      ],
    ),
  ];

  int selectedTab = 0;

  void createProject() async {
    final project = await Navigator.push<Project>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateProjectScreen(),
      ),
    );

    if (project != null) {
      setState(() => projects.add(project));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TrustPay AI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'TrustPay AI',
                applicationVersion: '0.1.0 Demo',
                children: [
                  const Text(
                    'AI-powered freelance milestone '
                    'and payment management prototype.',
                  ),
                ],
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: selectedTab == 0
          ? dashboard()
          : selectedTab == 1
              ? projectsPage()
              : paymentsPage(),
      floatingActionButton: selectedTab != 2
          ? FloatingActionButton.extended(
              onPressed: createProject,
              backgroundColor: teal,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('New Project'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (value) {
          setState(() => selectedTab = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Payments',
          ),
        ],
      ),
    );
  }

  Widget dashboard() {
    final totalBudget =
        projects.fold<int>(0, (sum, p) => sum + p.total);

    final completed = projects.fold<int>(
      0,
      (sum, p) => sum + p.completedCount,
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Welcome back!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: dark,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Manage your projects with confidence.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: summaryCard(
                'Projects',
                '${projects.length}',
                Icons.folder_copy_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: summaryCard(
                'Milestones Done',
                '$completed',
                Icons.task_alt,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        summaryCard(
          'Total Project Value (Demo USD)',
          '\$$totalBudget',
          Icons.account_balance_wallet_outlined,
        ),
        const SizedBox(height: 26),
        const Text(
          'Your Projects',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...projects.map(projectCard),
        const SizedBox(height: 75),
      ],
    );
  }

  Widget summaryCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      color: Colors.white,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: teal, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget projectCard(Project project) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailScreen(
                project: project,
              ),
            ),
          );
          setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                project.description,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 18),
              LinearProgressIndicator(
                value: project.progress,
                color: teal,
                backgroundColor: const Color(0xFFE5EEEE),
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${project.completedCount}/'
                    '${project.milestones.length} milestones',
                  ),
                  Text(
                    '\$${project.total}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: teal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget projectsPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'All Projects',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...projects.map(projectCard),
      ],
    );
  }

  Widget paymentsPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Payment Overview',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Demo only — no real PayPal transactions.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ...projects.expand(
          (project) => project.milestones.map(
            (m) => Card(
              color: Colors.white,
              child: ListTile(
                leading: Icon(
                  m.completed
                      ? Icons.check_circle
                      : Icons.schedule,
                  color: m.completed ? teal : Colors.orange,
                ),
                title: Text(m.title),
                subtitle: Text(project.title),
                trailing: Text('\$${m.amount}'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState
    extends State<CreateProjectScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final budgetController = TextEditingController();

  bool generating = false;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    budgetController.dispose();
    super.dispose();
  }

  Future<void> generateProject() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final budget = int.tryParse(budgetController.text.trim());

    if (title.isEmpty ||
        description.isEmpty ||
        budget == null ||
        budget < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a title, description and budget of at least \$4.',
          ),
        ),
      );
      return;
    }

    setState(() => generating = true);

    // Demo simulation. Replace with backend Gemini API.
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final amounts = [
      budget * 20 ~/ 100,
      budget * 30 ~/ 100,
      budget * 35 ~/ 100,
    ];

    amounts.add(budget - amounts.fold(0, (a, b) => a + b));

    final project = Project(
      title: title,
      description: description,
      milestones: [
        Milestone(title: 'Planning & UI Design', amount: amounts[0]),
        Milestone(title: 'Frontend Development', amount: amounts[1]),
        Milestone(title: 'Backend Integration', amount: amounts[2]),
        Milestone(title: 'Testing & Delivery', amount: amounts[3]),
      ],
    );

    setState(() => generating = false);

    Navigator.pop(context, project);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Project')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'AI Project Builder',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Describe your project to generate demo milestones.',
          ),
          const SizedBox(height: 22),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Project title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descriptionController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Project requirements',
              hintText: 'Build a responsive e-commerce website...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: budgetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Total budget (USD)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: generating ? null : generateProject,
            icon: const Icon(Icons.auto_awesome),
            label: Text(
              generating
                  ? 'Generating...'
                  : 'Generate Demo Milestones',
            ),
          ),
        ],
      ),
    );
  }
}

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState
    extends State<ProjectDetailScreen> {
  void openReview(Milestone milestone) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewScreen(milestone: milestone),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;

    return Scaffold(
      appBar: AppBar(title: Text(project.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            project.description,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Text(
            'Budget: \$${project.total} USD',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: teal,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Project Milestones',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...project.milestones.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final milestone = entry.value;

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                const Color(0xFFE2F5F1),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: teal),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              milestone.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text('\$${milestone.amount}'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        milestone.completed
                            ? 'Demo: Completed'
                            : 'Demo: Pending review',
                        style: TextStyle(
                          color: milestone.completed
                              ? teal
                              : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => openReview(milestone),
                        child: const Text('Open AI Review Demo'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ReviewScreen extends StatefulWidget {
  final Milestone milestone;

  const ReviewScreen({
    super.key,
    required this.milestone,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final evidenceController = TextEditingController();
  bool reviewed = false;

  @override
  void dispose() {
    evidenceController.dispose();
    super.dispose();
  }

  void reviewWork() {
    if (evidenceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter work evidence first.'),
        ),
      );
      return;
    }

    setState(() => reviewed = true);
  }

  void approveDemo() {
    setState(() => widget.milestone.completed = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Demo milestone marked completed. '
          'No payment was processed.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Work Review')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.milestone.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: evidenceController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Work evidence / description',
              hintText: 'Describe what has been completed...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: reviewWork,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Demo Review'),
          ),
          if (reviewed) ...[
            const SizedBox(height: 22),
            const Card(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review Preview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Evidence description received. '
                      'AI verification is not connected yet. '
                      'A real review will compare submitted '
                      'evidence with acceptance criteria.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: widget.milestone.completed
                  ? null
                  : approveDemo,
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark Completed (Demo)'),
            ),
          ],
        ],
      ),
    );
  }
}
