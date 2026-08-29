import os

file_path = "C:/Users/hp/Desktop/EthioClass/flutter/lib/screens/user/lesson_detail_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Fix the bullet point
content = content.replace("Ã¢â‚¬Â¢", "•")

# Fix emojis
content = content.replace("ðŸŽ‰", "🎉")
content = content.replace("ðŸ“–", "📖")

# Fix the comment lines that got mangled (Optional but cleaner)
content = content.replace("Ã¢â€ â‚¬", "─")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Fixed encoding issues in lesson_detail_screen.dart")
