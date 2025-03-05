// This file re-exports Flutter's widgets but with our overrides

export 'package:flutter/material.dart' hide Hero;
export 'hero.dart'; // Our custom version without animations
