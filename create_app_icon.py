#!/usr/bin/env python3
"""
Creates an app icon for TeslaCam Processor
"""

import os
from PIL import Image, ImageDraw, ImageFont
import subprocess

def create_icon():
    # Create a 1024x1024 icon (required for macOS)
    size = 1024
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background gradient (Tesla-inspired red/black)
    for i in range(size):
        color_value = int(20 + (i/size) * 30)
        draw.rectangle([0, i, size, i+1], fill=(180, 20, color_value, 255))
    
    # Draw car silhouette
    car_color = (255, 255, 255, 220)
    # Car body
    draw.rounded_rectangle([size*0.2, size*0.4, size*0.8, size*0.55], 
                           radius=50, fill=car_color)
    # Car top
    draw.rounded_rectangle([size*0.3, size*0.32, size*0.7, size*0.42], 
                           radius=30, fill=car_color)
    
    # Draw camera indicators (4 corners)
    camera_color = (100, 200, 255, 255)
    camera_size = 60
    # Front
    draw.ellipse([size*0.45, size*0.15, size*0.55, size*0.15+camera_size], 
                 fill=camera_color, outline=(255,255,255,255), width=3)
    # Back
    draw.ellipse([size*0.45, size*0.7, size*0.55, size*0.7+camera_size], 
                 fill=camera_color, outline=(255,255,255,255), width=3)
    # Left
    draw.ellipse([size*0.1, size*0.45, size*0.1+camera_size, size*0.55], 
                 fill=camera_color, outline=(255,255,255,255), width=3)
    # Right
    draw.ellipse([size*0.85, size*0.45, size*0.85+camera_size, size*0.55], 
                 fill=camera_color, outline=(255,255,255,255), width=3)
    
    # Draw connecting lines (showing coverage)
    line_color = (100, 200, 255, 128)
    draw.line([size*0.5, size*0.2, size*0.15, size*0.5], fill=line_color, width=3)
    draw.line([size*0.5, size*0.2, size*0.85, size*0.5], fill=line_color, width=3)
    draw.line([size*0.5, size*0.75, size*0.15, size*0.5], fill=line_color, width=3)
    draw.line([size*0.5, size*0.75, size*0.85, size*0.5], fill=line_color, width=3)
    
    # Add text
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 80)
        text = "TESLACAM"
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        draw.text((size/2 - text_width/2, size*0.82), text, 
                 fill=(255, 255, 255, 255), font=font)
    except:
        pass
    
    # Save icon
    icon_path = "/Users/jonathanalbiar/TeslaCamProcessor/AppIcon.png"
    img.save(icon_path, "PNG")
    print(f"Created icon at: {icon_path}")
    
    # Create iconset directory
    iconset_path = "/Users/jonathanalbiar/TeslaCamProcessor/AppIcon.iconset"
    os.makedirs(iconset_path, exist_ok=True)
    
    # Generate all required sizes for macOS
    sizes = [16, 32, 64, 128, 256, 512, 1024]
    for s in sizes:
        resized = img.resize((s, s), Image.Resampling.LANCZOS)
        resized.save(f"{iconset_path}/icon_{s}x{s}.png")
        if s <= 512:  # Create @2x versions for smaller sizes
            resized_2x = img.resize((s*2, s*2), Image.Resampling.LANCZOS)
            resized_2x.save(f"{iconset_path}/icon_{s}x{s}@2x.png")
    
    # Create .icns file
    subprocess.run(["iconutil", "-c", "icns", iconset_path])
    print(f"Created AppIcon.icns")
    
    return icon_path

if __name__ == "__main__":
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        print("Installing Pillow...")
        subprocess.run(["pip3", "install", "pillow"])
        from PIL import Image, ImageDraw, ImageFont
    
    create_icon()