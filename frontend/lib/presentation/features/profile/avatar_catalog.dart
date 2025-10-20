class GameAvatarOption {
  const GameAvatarOption({
    required this.id,
    required this.label,
    required this.character,
    required this.asset,
  });

  final String id;
  final String label;
  final String character;
  final String asset;
}

const String pixelAdventureGameId = 'pixel_adventure';

const List<GameAvatarOption> pixelAdventureAvatarOptions = [
  GameAvatarOption(
    id: 'mask_dude_idle',
    label: 'Mask Dude',
    character: 'Mask Dude',
    asset: 'assets/images/Avatars/Mask Dude/Idle (32x32).png',
  ),
  GameAvatarOption(
    id: 'ninja_frog_idle',
    label: 'Ninja Frog',
    character: 'Ninja Frog',
    asset: 'assets/images/Avatars/Ninja Frog/Idle (32x32).png',
  ),
  GameAvatarOption(
    id: 'pink_man_idle',
    label: 'Pink Man',
    character: 'Pink Man',
    asset: 'assets/images/Avatars/Pink Man/Idle (32x32).png',
  ),
  GameAvatarOption(
    id: 'virtual_guy_idle',
    label: 'Virtual Guy',
    character: 'Virtual Guy',
    asset: 'assets/images/Avatars/Virtual Guy/Idle (32x32).png',
  ),
];

const Map<String, List<GameAvatarOption>> gameAvatarCatalog = {
  pixelAdventureGameId: pixelAdventureAvatarOptions,
};

List<GameAvatarOption> avatarOptionsForGame(String gameId) =>
    gameAvatarCatalog[gameId] ?? const [];

GameAvatarOption defaultAvatarForGame(String gameId) {
  final options = avatarOptionsForGame(gameId);
  return options.isNotEmpty ? options.first : const GameAvatarOption(
    id: 'default',
    label: 'Default',
    character: 'Mask Dude',
    asset: 'assets/images/Avatars/Mask Dude/Idle (32x32).png',
  );
}

GameAvatarOption? resolveAvatarSelection(
  String gameId, {
  String? optionId,
  String? character,
  String? asset,
}) {
  final options = avatarOptionsForGame(gameId);
  if (options.isEmpty) return null;

  if (optionId != null) {
    final match =
        options.firstWhere((opt) => opt.id == optionId, orElse: () => options.first);
    if (match.id == optionId) return match;
  }

  if (character != null) {
    final match = options.firstWhere(
      (opt) => opt.character == character,
      orElse: () => options.first,
    );
    if (match.character == character) return match;
  }

  if (asset != null) {
    final match = options.firstWhere(
      (opt) => opt.asset == asset,
      orElse: () => options.first,
    );
    if (match.asset == asset) return match;
  }

  return options.first;
}
