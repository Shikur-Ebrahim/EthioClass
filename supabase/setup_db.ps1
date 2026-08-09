$sql = Get-Content "supabase\migrations\001_initial_schema.sql" -Raw
Set-Clipboard $sql
Start-Process "https://supabase.com/dashboard/project/ogbwhbzptrzjdetyygxt/sql/new"
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  EthioClass DB Setup - Auto Migration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your browser has been opened to the Supabase SQL Editor." -ForegroundColor Green
Write-Host "The full SQL schema has been copied to your clipboard." -ForegroundColor Green
Write-Host ""
Write-Host "To complete setup:" -ForegroundColor Yellow
Write-Host "  1. The SQL Editor is now open in your browser" -ForegroundColor White
Write-Host "  2. Click inside the editor area" -ForegroundColor White
Write-Host "  3. Press CTRL+A to select all" -ForegroundColor White
Write-Host "  4. Press CTRL+V to paste the schema" -ForegroundColor White
Write-Host "  5. Press the green 'Run' button (or Ctrl+Enter)" -ForegroundColor White
Write-Host ""
Write-Host "This creates tables: profiles, courses, course_modules, enrollments, bookmarks" -ForegroundColor Cyan
Write-Host ""
