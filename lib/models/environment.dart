enum Environment {
  development(1, 'Development'),
  staging(2, 'Staging'),
  qa(3, 'QA'),
  testing(4, 'Testing'),
  preProd(5, 'PreProd'),
  production(6, 'Production');

  final int id;
  final String name;
  
  const Environment(this.id, this.name);
} 