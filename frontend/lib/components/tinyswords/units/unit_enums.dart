enum UnitColor { blue, red, black, yellow }

enum UnitState { 
  idle, 
  run,
  // Warrior states
  attack1,
  attack2,
  guard,
  // Archer states 
  shoot,
  // Monk states
  heal,
  // Lancer states
  downAttack,
  downRightAttack,
  rightAttack,
  upRightAttack,
  upAttack,
  downDefence,
  downRightDefence,
  rightDefence,
  upRightDefence,
  upDefence,
}

enum UnitType { warrior, archer, monk, lancer }