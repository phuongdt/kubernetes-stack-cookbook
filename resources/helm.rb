resource_name :helm

property :version, String, default: ''
property :binary_path, String, default: '/usr/local/bin/helm'

default_action :install

load_current_value do
end

action :install do
  platform_cmd = Mixlib::ShellOut.new('uname')
  platform_cmd.run_command
  platform_cmd.error!
  platform = platform_cmd.stdout.strip.downcase

  version = new_resource.version

  arch_cmd = Mixlib::ShellOut.new('uname -m')
  arch_cmd.run_command
  arch_cmd.error!
  arch = arch_cmd.stdout.strip

  case arch
  when 'x86', 'i686', 'i386'
    arch = '386'
  when 'x86_64', 'aarch64'
    arch = 'amd64'
  when 'armv5*'
    arch = 'armv5'
  when 'armv6*'
    arch = 'armv6'
  when 'armv7*'
    arch = 'armv7'
  else
    arch = 'default'
  end

  if version.empty?
    latest_version_url = "curl -s https://api.github.com/repos/kubernetes/helm/releases/latest | grep 'tag_name' | cut -d\\\" -f4"
    latest_version_cmd = Mixlib::ShellOut.new(latest_version_url)
    latest_version_cmd.run_command
    latest_version_cmd.error!
    version = latest_version_cmd.stdout.strip
  end

  bash 'clean up the mismatched helm version' do
    code <<-EOF
          helm_binary=$(which helm);
          existing_version=$(helm version --short --client | cut -d ':' -f2 | sed 's/[[:space:]]//g' | sed 's/+.*//');
          if [ "$existing_version" != "#{version}" ]; then
            rm -rf $helm_binary || true;
          fi
        EOF
    only_if 'which helm'
  end

  download_url = "https://storage.googleapis.com/kubernetes-helm/helm-#{version}-#{platform}-#{arch}.tar.gz"

  bash 'install helm' do
    code <<-EOH
      curl #{download_url} | tar -xvz
      mv #{platform}-#{arch}/helm #{binary_path}
      EOH
  end
end

action :remove do
  execute 'remove helm' do
    command "rm -rf #{binary_path}"
    only_if 'which helm'
  end
end
