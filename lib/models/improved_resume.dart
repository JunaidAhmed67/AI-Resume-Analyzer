class ResumeJob {
  final String title;
  final String organization;
  final String dates;
  final List<String> bullets;
  const ResumeJob({
    required this.title,
    required this.organization,
    required this.dates,
    required this.bullets,
  });
}

class ResumeProject {
  final String name;
  final List<String> bullets;
  const ResumeProject({required this.name, required this.bullets});
}

class ImprovedResume {
  final String name;
  final String headline;
  final String contact;
  final String summary;
  final List<String> skills;
  final List<ResumeJob> experience;
  final List<ResumeProject> projects;
  final List<String> education;
  final List<String> certifications;

  const ImprovedResume({
    required this.name,
    required this.headline,
    required this.contact,
    required this.summary,
    required this.skills,
    required this.experience,
    required this.projects,
    required this.education,
    required this.certifications,
  });

  /// The PDF uses built-in fonts, so keep only simple characters.
  static String _clean(dynamic v) {
    var s = (v ?? '').toString();
    const map = {
      '\u2018': "'",
      '\u2019': "'",
      '\u201C': '"',
      '\u201D': '"',
      '\u2013': '-',
      '\u2014': '-',
      '\u2022': '-',
      '\u2026': '...',
      '\u00A0': ' ',
    };
    map.forEach((k, val) => s = s.replaceAll(k, val));
    s = String.fromCharCodes(s.runes.where((r) => r < 256));
    return s.trim();
  }

  static List<String> _strings(dynamic v) => v is List
      ? v.map(_clean).where((e) => e.isNotEmpty).toList()
      : <String>[];

  factory ImprovedResume.fromJson(Map<String, dynamic> j) {
    final jobs = <ResumeJob>[];
    final rawJobs = j['experience'];
    if (rawJobs is List) {
      for (final m in rawJobs) {
        if (m is Map) {
          jobs.add(ResumeJob(
            title: _clean(m['title']),
            organization: _clean(m['organization']),
            dates: _clean(m['dates']),
            bullets: _strings(m['bullets']),
          ));
        }
      }
    }
    final projects = <ResumeProject>[];
    final rawProjects = j['projects'];
    if (rawProjects is List) {
      for (final m in rawProjects) {
        if (m is Map) {
          projects.add(ResumeProject(
            name: _clean(m['name']),
            bullets: _strings(m['bullets']),
          ));
        }
      }
    }
    return ImprovedResume(
      name: _clean(j['name']),
      headline: _clean(j['headline']),
      contact: _clean(j['contact']),
      summary: _clean(j['summary']),
      skills: _strings(j['skills']),
      experience: jobs,
      projects: projects,
      education: _strings(j['education']),
      certifications: _strings(j['certifications']),
    );
  }

  String toPlainText() {
    final b = StringBuffer();
    b.writeln(name);
    if (headline.isNotEmpty) b.writeln(headline);
    if (contact.isNotEmpty) b.writeln(contact);
    if (summary.isNotEmpty) b.writeln('\nSUMMARY\n$summary');
    if (skills.isNotEmpty) {
      b.writeln('\nSKILLS');
      for (final s in skills) {
        b.writeln(s);
      }
    }
    if (experience.isNotEmpty) {
      b.writeln('\nEXPERIENCE');
      for (final e in experience) {
        b.writeln('${e.title} - ${e.organization} (${e.dates})');
        for (final x in e.bullets) {
          b.writeln('- $x');
        }
      }
    }
    if (projects.isNotEmpty) {
      b.writeln('\nPROJECTS');
      for (final p in projects) {
        b.writeln(p.name);
        for (final x in p.bullets) {
          b.writeln('- $x');
        }
      }
    }
    if (education.isNotEmpty) {
      b.writeln('\nEDUCATION');
      for (final e in education) {
        b.writeln(e);
      }
    }
    if (certifications.isNotEmpty) {
      b.writeln('\nCERTIFICATIONS');
      for (final c in certifications) {
        b.writeln(c);
      }
    }
    return b.toString();
  }
}
