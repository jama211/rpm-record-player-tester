#!/usr/bin/env python3
"""
App Icon Generator for RPM Record Player Tester
Generates all required iOS app icon sizes with a white record symbol on black background
"""

import os
from PIL import Image, ImageDraw, ImageFont
import json

# iOS App Icon sizes (in points, will be multiplied by scale factors)
ICON_SIZES = [
    # iPhone
    {"size": 60, "scale": 2, "idiom": "iphone"},  # 120x120
    {"size": 60, "scale": 3, "idiom": "iphone"},  # 180x180
    {"size": 40, "scale": 2, "idiom": "iphone"},  # 80x80
    {"size": 40, "scale": 3, "idiom": "iphone"},  # 120x120
    {"size": 29, "scale": 2, "idiom": "iphone"},  # 58x58
    {"size": 29, "scale": 3, "idiom": "iphone"},  # 87x87
    {"size": 20, "scale": 2, "idiom": "iphone"},  # 40x40
    {"size": 20, "scale": 3, "idiom": "iphone"},  # 60x60
    
    # iPad
    {"size": 76, "scale": 2, "idiom": "ipad"},    # 152x152
    {"size": 76, "scale": 1, "idiom": "ipad"},    # 76x76
    {"size": 40, "scale": 1, "idiom": "ipad"},    # 40x40
    {"size": 40, "scale": 2, "idiom": "ipad"},    # 80x80
    {"size": 29, "scale": 1, "idiom": "ipad"},    # 29x29
    {"size": 29, "scale": 2, "idiom": "ipad"},    # 58x58
    {"size": 20, "scale": 1, "idiom": "ipad"},    # 20x20
    {"size": 20, "scale": 2, "idiom": "ipad"},    # 40x40
    
    # App Store
    {"size": 1024, "scale": 1, "idiom": "ios-marketing"},  # 1024x1024
]

def create_record_icon(size):
    """Create a record icon with white symbol on black background"""
    # Create black background
    img = Image.new('RGBA', (size, size), 'black')
    draw = ImageDraw.Draw(img)
    
    # Calculate dimensions for the record
    center = size // 2
    outer_radius = int(size * 0.4)  # 40% of image size
    inner_radius = int(size * 0.08)  # 8% of image size for center hole
    
    # Draw outer circle (record edge)
    draw.ellipse([center - outer_radius, center - outer_radius, 
                  center + outer_radius, center + outer_radius], 
                 outline='white', width=int(size * 0.02))
    
    # Draw inner circle (center hole)
    draw.ellipse([center - inner_radius, center - inner_radius,
                  center + inner_radius, center + inner_radius],
                 fill='white')
    
    # Add some groove lines for authenticity
    for i in range(3):
        groove_radius = outer_radius - int(size * 0.05) - (i * int(size * 0.04))
        if groove_radius > inner_radius * 2:
            draw.ellipse([center - groove_radius, center - groove_radius,
                         center + groove_radius, center + groove_radius],
                        outline='white', width=1)
    
    return img

def generate_contents_json():
    """Generate the Contents.json file for the app icon set"""
    images = []
    
    for icon_info in ICON_SIZES:
        pixel_size = icon_info["size"] * icon_info["scale"]
        filename = f"icon_{pixel_size}x{pixel_size}.png"
        
        images.append({
            "filename": filename,
            "idiom": icon_info["idiom"],
            "scale": f"{icon_info['scale']}x",
            "size": f"{icon_info['size']}x{icon_info['size']}"
        })
    
    contents = {
        "images": images,
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    return contents

def main():
    # Define paths
    project_root = os.path.dirname(os.path.abspath(__file__))
    assets_path = os.path.join(project_root, "RPM Record Player Tester", "Assets.xcassets")
    app_icon_path = os.path.join(assets_path, "AppIcon.appiconset")
    
    print("🎵 Generating RPM Record Player Tester App Icons...")
    print(f"Project root: {project_root}")
    print(f"App icon path: {app_icon_path}")
    
    # Create the directory if it doesn't exist
    os.makedirs(app_icon_path, exist_ok=True)
    
    # Generate all icon sizes
    generated_files = []
    for icon_info in ICON_SIZES:
        pixel_size = icon_info["size"] * icon_info["scale"]
        filename = f"icon_{pixel_size}x{pixel_size}.png"
        filepath = os.path.join(app_icon_path, filename)
        
        print(f"  Generating {filename} ({pixel_size}x{pixel_size})")
        
        # Create and save the icon
        icon = create_record_icon(pixel_size)
        icon.save(filepath, "PNG")
        generated_files.append(filename)
    
    # Generate Contents.json
    contents_json = generate_contents_json()
    contents_path = os.path.join(app_icon_path, "Contents.json")
    
    with open(contents_path, 'w') as f:
        json.dump(contents_json, f, indent=2)
    
    print(f"  Generated Contents.json")
    print(f"\n✅ Successfully generated {len(generated_files)} app icon files!")
    print(f"📁 Icons saved to: {app_icon_path}")
    print("\n🔄 Next steps:")
    print("1. Open your Xcode project")
    print("2. The new app icons should automatically appear in Assets.xcassets > AppIcon")
    print("3. Build and run your project to see the new icon!")

if __name__ == "__main__":
    try:
        main()
    except ImportError as e:
        print("❌ Missing required library!")
        print("Please install Pillow (PIL) by running:")
        print("  pip install Pillow")
        print(f"\nError: {e}")
    except Exception as e:
        print(f"❌ Error: {e}")
