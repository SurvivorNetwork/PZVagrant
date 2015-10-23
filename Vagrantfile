# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'net/http'
require 'socket'

VAGRANT_COMMAND = ARGV[0]

pzv_config    = {
  'dir'             => File.expand_path( File.dirname( __FILE__ ) ),
  'steam'           => ENV[ 'PZV_STEAM' ] ? ! ENV[ 'PZV_STEAM' ] == 'false' : true,
  'steam_app_id'	=> ENV[ 'PZV_STEAM_APP_ID' ] || false,
  'beta_name'       => ENV[ 'PZV_BETA' ] || false,                                                   # i.e. 'IWBUMS'
  'beta_password'   => ENV[ 'PZV_BETA_PW' ] || false,
  'ip_private'      => ENV[ 'PZV_IP_PRIVATE' ] || '10.0.8.60',
  'ip_lan'          => ENV[ 'PZV_IP_LAN' ] || 'dhcp',
  'ip_wan'          => ENV[ 'PZV_IP_WAN' ] || nil,
  'max_players'     => ENV[ 'PZV_MAX_PLAYERS' ] ? ENV[ 'PZV_MAX_PLAYERS' ].to_i : 10,
  'handshake_port'  => ENV[ 'PZV_PORT' ] ? ENV[ 'PZV_PORT' ].to_i : 16261,
  'steam_port_1'    => ENV[ 'PZV_STEAM_PORT_1' ] ? ENV[ 'PZV_STEAM_PORT_1' ].to_i : 8766,
  'steam_port_2'    => ENV[ 'PZV_STEAM_PORT_2' ] ? ENV[ 'PZV_STEAM_PORT_2' ].to_i : 8767,
  'visibility'      => ENV[ 'PZV_VISIBILITY' ] || 'lan',                                             # private | lan | wan
  'web_interface'   => ENV[ 'PZV_WEB_INTERFACE' ] ? ! ENV[ 'PZV_WEB_INTERFACE' ] == 'false' : true,
  'serve_from_host' => ENV[ 'PZV_LOCALHOST' ] ? ! ENV[ 'PZV_LOCALHOST' ] == 'false' : false,         # Serve from host interface IP, or own bridged LAN IP
  'memory'          => ENV[ 'PZV_MEMORY' ] ? ENV[ 'PZV_MEMORY' ].to_i : 1028,
  'pz_memory'       => ENV[ 'PZV_PZ_MEMORY' ] ? ENV[ 'PZV_PZ_MEMORY' ].to_i : nil,
  'cpus'            => ENV[ 'PZV_CPUS' ] ? ENV[ 'PZV_CPUS' ].to_i : 1,
  'cpu_cap'         => ENV[ 'PZV_CPU_CAP' ] ? ENV[ 'PZV_CPU_CAP' ].to_s : '70',
  'autorun'         => ENV[ 'PZV_AUTORUN' ] ? ! ENV[ 'PZV_AUTORUN' ] == 'false' : true,
  'autoupdate'      => ENV[ 'PZV_AUTOUPDATE' ] ? ! ENV[ 'PZV_AUTOUPDATE' ] == 'false' : true,
  'hostname'        => ENV[ 'PZV_HOSTNAME' ] ? ENV[ 'PZV_HOSTNAME' ].to_s : nil,
  'vagrant_box'     => ENV[ 'PZV_VAGRANT_BOX' ] ? ENV[ 'PZV_VAGRANT_BOX' ] : 'debian/jessie64'
}

if File.exists?( File.join( pzv_config[ 'dir' ], 'pzv-conf' ) )
  eval( IO.read( File.join( pzv_config[ 'dir' ] ,'pzv-conf' ) ), binding )
end

Vagrant.require_version '>= 1.4.0'
Vagrant.configure(2) do |config|
  vagrant_version = Vagrant::VERSION.sub(/^v/, '')
  steam_app_id = pzv_config[ 'app_id' ] ? pzv_config[ 'app_id' ] : ( pzv_config[ 'steam' ] ? 380870 : 10860 )
  pzv_version = '0.1'
  notes=[]
  ports=[]

  # If calling vagrant ssh, log in as the steam user
  if VAGRANT_COMMAND == 'ssh'
      #config.ssh.username = 'steam'
  end

####
# Implicit Configuration Notes and Adjustments
####
  # Give the game no more than 80% of the VM's memory
  max_game_memory = (pzv_config[ 'memory' ].to_f * 0.8).round
  if ! pzv_config[ 'pz_memory' ]
    notes << 'PZV set Project Zomboid\'s memory allocation to ' + max_game_memory.to_s + ' MB by default, which is the maximum recommended 80% of system memory.'
    pzv_config[ 'pz_memory' ] = max_game_memory
  end

  if pzv_config[ 'pz_memory' ].to_i > max_game_memory
    notes << 'PZV reduced Project Zomboid\'s memory allocation from the configured ' + pzv_config[ 'pz_memory' ].to_s + ' MB to ' + max_game_memory.to_s + ' MB, as allocating more than 80% of the VM\'s memory can cause instability.'
    pzv_config[ 'pz_memory' ] = max_game_memory
  end

  #   
  if ! pzv_config[ 'hostname' ]
    pzv_config[ 'hostname' ] = File.basename( Dir.pwd ) + '-' + pzv_config[ 'vagrant_box' ].partition('/').last
  end

  #
  #if ! pzv_config[ 'max_players' ]
  #  pzv_config[ 'max_players' ] = pzv_config[ 'max_players' ]
  #end

  # Visibility interpretation and Steam-integration adjustment
  visibility = 'private' == pzv_config[ 'visibility' ] ? 0 : 1
  if 'wan' == pzv_config[ 'visibility' ]
    visibility = 2;
  else
    if pzv_config[ 'steam' ]
      notes << 'The server\'s visibility was upgraded from "' + pzv_config[ 'visibility' ] + '" to "wan" because the configuration specifies Steam integration, which requires public visibility in order to communicate with the Steam servers.'
    end
  end

  if pzv_config[ 'steam' ]
    visibility = 2
  end

  # Host CPU Cap Warning
  if pzv_config[ 'cpu_cap' ].to_i > 70
    notes << 'You have configured the VM to use up to ' + pzv_config[ 'cpu_cap' ].to_s + '% of ' + pzv_config[ 'cpus' ].to_s + ' of your system\'s logical processors. If you do not have additional processor resources available, the performance of your machine may degrade if the server is subjected to a heavy work-load.'
  end

  # Serve-from-host & LAN IP assumption notes
  if pzv_config[ 'serve_from_host' ]
     notes << 'PZV is configured to proxy Project Zomboid network activity through your host machine\'s ports. In this mode, you should interact with the server as though it were installed natively.'

    if 'dhcp' == pzv_config[ 'ip_lan' ] && ! first_private_ipv4.nil?
      pzv_config[ 'ip_lan' ] = first_private_ipv4.ip_address

      note = 'Your configuration did not specify your machine\'s LAN IPv4 address, so PZV made an educated guess that it\'s ' + pzv_config[ 'ip_lan' ] + '.'

      if visibility == 1
        note << ' If players will access this server over LAN, make sure that this is address corresponds to the shared network. If it is incorrect, you will need to specify the proper LAN IPv4 manually in your PZV configuration.'
      end

      if visibility == 2
        note << ' This should be the address for the network through which you access the public internet (WAN).'
      end
      
      notes << note
    end
  end

  if ! pzv_config[ 'ip_wan' ]
    pzv_config[ 'ip_wan' ] = Net::HTTP.get( 'ipecho.net', '/plain' )
    notes << 'Your configuration did not specify your machine\'s WAN IPv4 address, so PZV made an educated guess that it\'s ' + pzv_config[ 'ip_wan' ] + '. If your machine accesses the internet through multiple networks, you may need to manually configure this setting.'
  end
####
# VM Configuration
####
  config.vm.hostname = pzv_config[ 'hostname' ] #can't set a hostname without admin privileges - possible solutions, see http://stackoverflow.com/questions/28025940
  config.vm.box      = pzv_config[ 'vagrant_box' ]
  # config.vm.box_check_update = false
  
  config.vm.provider :virtualbox do |v|
    v.name = pzv_config[ 'hostname' ]
    v.customize [ 'modifyvm', :id, '--memory', pzv_config[ 'memory' ] ]
    v.customize [ 'modifyvm', :id, '--cpus', pzv_config[ 'cpus' ] ]
    v.customize [ 'modifyvm', :id, '--cpuexecutioncap',  pzv_config[ 'cpu_cap' ] ]
  end

####
# Network Interfaces
#
# I can't think of any reason to use seperate internal port mappings to the game server itself, but that might have to be
# revisited. None of these ports need to be forwarded from the guest to the host if we're hosting from a bridged interface
# instead of localhost's IP.
#
# TODO: some of the port forwarding shouldn't be allowed to autocorrect. If the handshake or any single player port conflicts,
# the entire range needs to be shifted. Need to implement post-provisioning checks for this and more in the guest shell.
####
  
  # Configure a private, host-only IP for the VM. If none was specified, VirtualBox should assign one on a virtual newtork with DHCP
  config.vm.network 'private_network', ip: pzv_config[ 'ip_private' ]

  # If hosting a Steam and/or WAN server, set up a LAN IP on the bridged network adapter. If ip_lan is "dhcp", it will try to lease one from the network automatically
  if visibility > 1
    config.vm.network 'public_network', ip: pzv_config[ 'ip_lan' ]
  end

  # If serving from the host machine, forward all relevant game ports to the host's network interface
  if pzv_config[ 'serve_from_host' ]
    # Forward the PZ server's handshake port. TODO: expand this to allow different host/guest ports
    config.vm.network 'forwarded_port', guest: pzv_config[ 'handshake_port' ], host: pzv_config[ 'handshake_port' ], protocol: 'udp', autocorrect: true
  end

  # If running a server with Steam integrations enabled, forward the Steam server ports to the VM
  if pzv_config[ 'steam' ]
    if pzv_config[ 'serve_from_host' ]
      config.vm.network 'forwarded_port', guest: pzv_config[ 'steam_port_1' ], host: pzv_config[ 'steam_port_1' ], protocol: 'tcp'
      config.vm.network 'forwarded_port', guest: pzv_config[ 'steam_port_1' ], host: pzv_config[ 'steam_port_1' ], protocol: 'udp'
      config.vm.network 'forwarded_port', guest: pzv_config[ 'steam_port_2' ], host: pzv_config[ 'steam_port_2' ], protocol: 'tcp'
      config.vm.network 'forwarded_port', guest: pzv_config[ 'steam_port_2' ], host: pzv_config[ 'steam_port_2' ], protocol: 'udp'
    end

    ports << { 'port' => pzv_config[ 'steam_port_1' ], 'tcp' => true, 'udp' => true }
    ports << { 'port' => pzv_config[ 'steam_port_2' ], 'tcp' => true, 'udp' => true }
  end

  ports << { 'port' => pzv_config[ 'handshake_port' ], 'tcp' => false, 'udp' => true }

  # Forward an additional TCP port for every alloted player
  for i in ( pzv_config[ 'handshake_port' ] + 1 )..( pzv_config[ 'handshake_port' ] + pzv_config[ 'max_players' ] )
    if pzv_config[ 'serve_from_host' ]
      config.vm.network 'forwarded_port', guest: i, host: i, protocol: 'tcp', autocorrect: true
    end
  end

  if visibility > 1
    ports << { 'port' => ( pzv_config[ 'handshake_port' ] + 1 ).to_s + '-' + ( pzv_config[ 'handshake_port' ] + pzv_config[ 'max_players' ] ).to_s, 'tcp' => true, 'udp' => false }
  end

####
# Provisioners
####
  config.vm.provision 'PZV-Setup', type: 'shell', path: File.join( 'pzv', 'provision', 'provision.sh' )

  if pzv_config[ 'autoupdate' ]
    config.vm.provision 'PZV-Update', type: 'shell', path: File.join( 'pzv', 'provision', pzserver.update.sh' ), run: 'always'
  end

  if pzv_config[ 'autorun' ]
    config.vm.provision 'PZV-Run', type: 'shell', path: File.join( 'pzv', 'provision', pzserver.start.sh' ), run: 'always'
  end



####
# Up Message
####

  #TODO: guest-shell checks for automatically assigned IPs and whether or not they were succesful, create notes informing user

  server_config_message = [
    'Host Name : ' + pzv_config[ 'hostname' ],
    'Host OS   : ' + pzv_config[ 'vagrant_box' ],
    ' ',
    'Hardware:',
    '  ► Memory       : ' + pzv_config[ 'memory' ].to_s + ' MB',
    '  ► CPUs         : ' + pzv_config[ 'cpus' ].to_s,
    '  ► Host CPU Cap : ' + pzv_config[ 'cpu_cap' ].to_s + '%',
    ' ',
    'Network:',
    '  ► Visibility      : localhost[ ' + ( visibility >= 0 ? 'X' : ' ' ) + ' ]    LAN[ ' + ( visibility >= 1 ? 'X' : ' ' ) + ' ]    WAN[ ' + ( visibility >= 2 ? 'X' : ' ' ) + ' ]',
    '  ► Private IP      : ' + pzv_config[ 'ip_private' ],
    '  ► LAN (local) IP  : ' + pzv_config[ 'ip_lan' ],
    '  ► WAN (public) IP : ' + pzv_config[ 'ip_wan' ],
    ' '
  ]

  if visibility > 1
    server_config_message << '  ► Forward the following ports to ' + ( 'dhcp' == pzv_config[ 'ip_lan' ] ? 'PZV' : pzv_config[ 'ip_lan' ] )
    server_config_message << ' '
    server_config_message << '    --- TCP --- UDP --- port ---'
    ports.each do |i|
      server_config_message << '         ' + ( i[ 'tcp' ] ? 'X' : ' ' ) + '       ' + ( i[ 'udp' ] ? 'X' : ' ' ) + '      ' + i[ 'port' ].to_s
    end
    server_config_message << ' '
  end

  notes_block = [ ' ' ]
  if notes.length > 0
    notes.map! do |note|
      [ ' ► ' + note, ' ' ]
    end

    notes_block << print_block([
        ' ',
        'PZVagrant created the following notes while interpreting your configuration:',
        ' ',
        notes
        ],
        {
          'width'        => 76,
          'header'       => [ '|▬▬▬ Configuration Notes ', '▬', '|' ],
          'footer'       => [ '|', '▬', '|' ],
          'border'       => '|',
          'return_array' => true
        })

    notes_block << ' '
  end

  config.vm.post_up_message = print_block([
      ' ',
      %q< ____    ________   __  __                                         __      >,
      %q</\  _ `\/\_____  \ /\ \/\ \                                       /\ \__   >,
      %q<\ \ \L\ \/____// / \ \ \ \ \     __       __   _ __    __      ___\ \  _\  >,
      %q< \ \  __/    // /   \ \ \ \ \  /'__`\   /'_ `\/\` __\/'__`\  /' _ `\ \ \/  >,
      %q<  \ \ \/    // / ___ \ \ \_/ \/\ \L\ \_/\ \L\ \ \ \//\ \L\ \_/\ \/\ \ \ \_ >,
      %q<   \ \_\    /\_______\\\\ `\___/\ \__/.\_\ \____ \ \_\\\\ \__/.\_\ \_\ \_\ \__\\>,
      %q<    \/_/    \/_______/ `\/__/  \/__/\/_/\/___L\ \/_/ \/__/\/_/\/_/\/_/\/__/>,
      %q<                                          /\____/                          >,
      %q<                                          \_/__/                           >,
      ' ',
      '  SurvivorNet PZVagrant v' + pzv_version.to_s + '  -  http://survivor.network/tools/pz-vagrant',
      ' ',
      'PZVagrant has finished provisioning a Project Zomboid Dedicated Server Linux Virtual Machine (or colloquially, "PZDSLVM"). Please review the details below to ensure they live up to your envisioned apocalypse. Note that the configuration displayed is only that which PZV attempted to apply - live settings may vary.',
      ' ',
      print_block([
        ' ',
        server_config_message,
        ' '
        ],
        {
          'width'        => 76,
          'header'       => [ '|▬▬▬ Server VM Configuration ', '▬', '|' ],
          'footer'       => [ '|', '▬', '|' ],
          'border'       => '|',
          'return_array' => true
        }),
      ' ',
      print_block([
        ' ',
        'Memory             : ' + pzv_config[ 'pz_memory' ].to_s + ' MB',
        'Maximum Players    : ' + pzv_config[ 'max_players' ].to_s,
        'Steam Integration  : ' + ( pzv_config[ 'steam' ] ? 'Enabled' : 'Disabled' ),
        'App ID             : ' + steam_app_id.to_s,
        'Development Branch : ' + ( pzv_config[ 'beta_name' ] ? pzv_config[ 'beta_name' ] : 'stable' ),
        ' ',
        'Automation:',
        '  ► Auto-Run     : ' + ( pzv_config[ 'autorun' ] ? 'Enabled' : 'Disabled' ),
        '  ► Auto-Update  : ' + ( pzv_config[ 'autoupdate' ] ? 'Enabled' : 'Disabled' ),
        '  ► Auto-Restart : ' + ( pzv_config[ 'autorestart' ] ? 'Enabled' : 'Disabled' ),
        ' '
        ],
        {
          'width'        => 76,
          'header'       => [ '|▬▬▬ PZ Server Configuration ', '▬', '|' ],
          'footer'       => [ '|', '▬', '|' ],
          'border'       => '|',
          'return_array' => true
        }),
      notes_block
    ],
    {
      'width'         => 84,
      'border_repeat' => 2,
      'padding'       => 2,
      'header'        => true,
      'footer'        => true
    }) + "\r\n"
end

def first_private_ipv4
    Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
end

#TODO: Wrap at word breaks
def print_block( lines, options )
  options[ "padding" ] ||= 2
  border_repeat = options[ "border_repeat" ] ? options[ "border_repeat" ] : 1
  padding       = options[ "padding" ] ? options[ "padding" ] : 1
  border        = options[ "border" ] ? options[ "border" ] : "█"
  header        = options[ "header" ] ? options[ "header" ] : false
  footer        = options[ "footer" ] ? options[ "footer" ] : false
  width         = options[ "width" ] ? options[ "width" ] : 100
  decor_width   = border.length * border_repeat * 2 + padding * 2
  max_line_width= width - decor_width;
  output        = options[ "return_array" ] ? [] : "\r\n"
  header_string = ""
  footer_string = ""

  # Unpack nested line arrays
  lines.flatten!

  if lines.length > 0
    # Header
    if header
      if header == true
        header = border
      end

      if header.length == 1
        header_string << header[0] * width
      else
        header_string << header[0]
        fill_length = width - ( header.kind_of?(Array) ? header[0].length : 1 )

        if header.length == 3
          fill_length = fill_length - ( header.kind_of?(Array) ? header[2].length : 1 )
        end

        header_string << header[1] * ( fill_length / header[1].length )

        if header.length == 3
          header_string << header[2]
        end
      end

      output << header_string

      if ! options[ "return_array" ]
        output << "\r\n"
      end
    end
    # /Header

    # Body
    lines.each_with_index do |line, index|
      # TODO: split up lines containing a newline sequence

      # Wrap long lines. Ruby is absurd nonsense... I'm vaguely inclined to learn more. TODO: learn more. Then refine this function just for the thrill.
      if line.length > max_line_width
        line.slice!( max_line_width...line.length ).chars.each_slice( max_line_width ).with_index do |(*newline_chars), offset|
          if newline_chars[0] == " "
            newline_chars.shift
          end

          lines.insert( index + offset + 1, newline_chars.join )
        end
      end

      output << ( border * border_repeat ) + ( " " * padding ) + line + ( " " * ( max_line_width - line.length ) ) + ( " " * padding ) + ( border * border_repeat )

      if ! options[ "return_array" ]
        output << "\r\n"
      end
    end
    # /Body

    # Footer
    if footer
      if footer == true
        footer = border
      end

      if footer.length == 1
        footer_string << footer[0] * width
      else
        footer_string << footer[0]
        fill_length = width - ( footer.kind_of?(Array) ? footer[0].length : 1 )

        if footer.length == 3
          fill_length = fill_length - ( footer.kind_of?(Array) ? footer[2].length : 1 )
        end

        footer_string << footer[1] * ( fill_length / footer[1].length )

        if footer.length == 3
          footer_string << footer[2]
        end
      end

      output << footer_string

      if ! options[ "return_array" ]
        output << "\r\n"
      end
    end
    # /Footer
  end

  return output
end
