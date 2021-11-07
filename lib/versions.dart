class Version {
  final String name;
  Version(this.name);

  static const _qualifiers = {
    "dev": 1,
    "alpha": 4,
    "beta": 5,
    "": 10,
    "hotfix": 11,
    "patch": 12
  };
  
  int get rootVersion => int.parse(name.split(" ").first);
  int get qualifier => name.contains(" ") ?_qualifiers[name.split(" ")[1]] ?? 10 : 10;
  int get lastVersion => name.contains(" ") ? int.parse(name.split(" ").last) : 0;

  bool operator >(Version right) {
    if (this.rootVersion != right.rootVersion) {
      return this.rootVersion > right.rootVersion;
    } else if (this.qualifier != right.qualifier) {
      return this.qualifier > right.qualifier;
    } else if (this.lastVersion != right.lastVersion) {
      return this.lastVersion > right.lastVersion;
    } else return false;
  }
  bool operator <(Version right) {
    if (this.rootVersion != right.rootVersion) {
      return this.rootVersion < right.rootVersion;
    } else if (this.qualifier != right.qualifier) {
      return this.qualifier < right.qualifier;
    } else if (this.lastVersion != right.lastVersion) {
      return this.lastVersion < right.lastVersion;
    } else return false;
  }
  bool operator >=(Version right) {
    if (this.rootVersion != right.rootVersion) {
      return this.rootVersion >= right.rootVersion;
    } else if (this.qualifier != right.qualifier) {
      return this.qualifier >= right.qualifier;
    } else if (this.lastVersion != right.lastVersion) {
      return this.lastVersion >= right.lastVersion;
    } else return this.name == right.name;
  }
  bool operator <=(Version right) {
    if (this.rootVersion != right.rootVersion) {
      return this.rootVersion <= right.rootVersion;
    } else if (this.qualifier != right.qualifier) {
      return this.qualifier <= right.qualifier;
    } else if (this.lastVersion != right.lastVersion) {
      return this.lastVersion <= right.lastVersion;
    } else return this.name == right.name;
  }
}