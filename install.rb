# Copy the assets into RAILS_ROOT/public/
RAILS_ROOT = File.join(File.dirname(__FILE__), '../../../')
 
FileUtils.cp_r( 
  Dir[File.join(File.dirname(__FILE__), 'public')], 
  File.join(RAILS_ROOT),
  :verbose => true
)
 
# Show the README text file
puts IO.read(File.join(File.dirname(__FILE__), 'README')