require 'facter'
Facter.add("rhn_id") do
  confine :kernel => :Linux
  setcode do
    id = nil
    id_file = '/etc/sysconfig/rhn/systemid'
    if File.exists? id_file
      open(id_file) { |f| id = f.grep(/ID-/)[0] }
    end
    id.nil? ? 0 : id.gsub(/\D+(\d+)\D+/,'\1').to_i
  end
end
