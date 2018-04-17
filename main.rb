require 'socket'
require 'date'

NTP_FIELDS = [ :byte1, :stratum, :poll, :precision, :delay, :delay_fb,
                   :disp, :disp_fb, :ident, :ref_time, :ref_time_fb, :org_time,
                   :org_time_fb, :recv_time, :recv_time_fb, :trans_time,
                   :trans_time_fb ]

def convert_time(ntp_timestamp)
  unix_timestamp = ntp_timestamp - 2208988800
  datetime = DateTime.strptime(unix_timestamp.to_s, '%s')
  return datetime.to_time.strftime("%a %b %e %H:%M:%S %Z %Y")
end

def parse_packet(data)
  packetdata = data.unpack("a C3   n B16 n B16 H8   N B32 N B32   N B32 N B32")
  packet_data_by_field = {}
  NTP_FIELDS.each do |field|
    packet_data_by_field[field] = packetdata.shift
  end
  return packet_data_by_field
end

def create_request
  bytes = Array.new(48, 0)
  bytes[0] = 0x1b
  return bytes.pack("c*")
end

def get_ntp_time(timeout)
  sock = UDPSocket.new
  sock.connect("pool.ntp.org", 123)
  sock.print(create_request)
  sock.flush
  read, write, error = IO.select [sock], nil, nil, timeout
  if !read.nil?
    data, _ = sock.recvfrom(960)
    packet_data = parse_packet(data)
    return convert_time(packet_data[:trans_time])
  end
end

wait_period = 1
time = get_ntp_time(wait_period)
while !time
  wait_period *= 2
  p wait_period
  time = get_ntp_time(wait_period)
  #sleep wait_period
end
p time
