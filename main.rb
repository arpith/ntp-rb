require 'socket'
require 'date'
NTP_FIELDS = [ :byte1, :stratum, :poll, :precision, :delay, :delay_fb,
                   :disp, :disp_fb, :ident, :ref_time, :ref_time_fb, :org_time,
                   :org_time_fb, :recv_time, :recv_time_fb, :trans_time,
                   :trans_time_fb ]
sock = UDPSocket.new
sock.connect("pool.ntp.org", 123)
bytes = Array.new(48, 0)
bytes[0] = 0x1b
msg = bytes.pack("c*")
sock.print(msg)
sock.flush
read, write, error = IO.select [sock], nil, nil
if read.nil?
  p "help"
else
  data, _ = sock.recvfrom(960)
  packetdata = data.unpack("a C3   n B16 n B16 H8   N B32 N B32   N B32 N B32")
  packet_data_by_field = {}
  NTP_FIELDS.each do |field|
    packet_data_by_field[field] = packetdata.shift
  end
  timezone = Time.now.zone
  unix_timestamp = packet_data_by_field[:trans_time] - 2208988800
  datetime = DateTime.strptime(unix_timestamp.to_s, '%s')
  p datetime.strftime("%+")
end
