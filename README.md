# Horizon Nix flake

打包上游 [Horizon Launcher](https://github.com/horizon-rust/horizon/releases?q=launcher) 的官方 Linux x86_64 二进制发行包，不从源码编译。目前仅支持 `x86_64-linux`。版本由 `flake.lock` 中锁定的发行信息决定。

上游将游戏更新转移到 Nightly，旧的 `v0.2.97` 虽被 GitHub API 标记为 Latest，但发行说明已标记其过时。因此本 flake 默认提供启动器，由启动器管理游戏版本。

## 使用

在本目录运行：

```sh
nix build path:.
./result/bin/horizon-launcher --help
nix run path:.
# 安装到用户 profile，并提供桌面菜单入口
nix profile install path:.
```

也可使用显式输出 `path:.#horizon-launcher`。需要开启 Nix 的 `nix-command` 和 `flakes` 功能。

NixOS 配置示例（将路径改为自己的位置）：

```nix
{
  inputs.horizon.url = "path:/home/gujial/repos/horizon-flake";

  outputs = { nixpkgs, horizon, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        ({ ... }: {
          environment.systemPackages = [
            horizon.packages.x86_64-linux.horizon-launcher
          ];
        })
      ];
    };
  };
}
```

也提供 `overlays.default`，应用后可以使用 `pkgs.horizon-launcher`。

## 运行方式与更新

原生模组构建环境包含 C/C++ 编译器、binutils、`pkg-config`、Make、CMake、Ninja、C 标准库及 Linux 头文件，以及 ALSA、libudev、OpenSSL、zlib 开发文件。Rust/Cargo 继续由启动器下载并固定版本。请通过 `nix run path:.` 或 `result/bin/horizon-launcher` 启动，直接运行 `unwrapped` 二进制无法获得这些依赖。依赖依据上游 [原生模组构建说明](https://github.com/horizon-rust/horizon/blob/launcher%400.2.69/docs/native-mods.md)；特殊模组可能另需额外系统库。

- 使用 `buildFHSEnv` 提供启动器及其下载的游戏、准备工具和服务器所需的 Linux 运行环境，包含 X11、Wayland、Vulkan、音频库及 Java/Python 工具。运行时需要允许非特权用户命名空间，NixOS 默认支持。
- 通过 `HORIZON_LAUNCHER_NO_SELF_UPDATE=1` 禁用启动器自更新，避免尝试修改只读 Nix store。更新启动器使用下方 flake 命令，无需手动修改版本或 SHA-256。
- 游戏由启动器另行下载到用户目录，不属于 Nix 构建闭包，也不由 `flake.lock` 固定。Minecraft 账号、游戏数据准备及图形驱动仍按上游要求配置。
- `flake.lock` 同时固定 nixpkgs 和 `horizon-release` 发行信息快照；使用 `nix flake update` 更新两者。

仅更新启动器发行信息（保留 nixpkgs 版本）：

```sh
nix flake update horizon-release --flake path:. --refresh
nix build path:.
./result/bin/horizon-launcher --version
```

`--refresh` 避免沿用 Nix 的 HTTP 下载缓存。`horizon-release` 是 GitHub Releases API 返回的最近 100 条发行记录；`release.nix` 筛选非草稿、非预发行的 `launcher@…` 标签，再按发布时间选择最新一条，读取 Linux 归档地址和 GitHub 提供的 SHA-256。缺少启动器、目标资产或校验值时会报错，不会退回旧游戏包或跳过校验。如果未来最近 100 条记录中不再包含正式启动器版本，需要调整发行信息来源。

普通构建使用已锁定的快照，不会自动追踪新发行版。GitHub API 的下载次数等元数据变化也可能改变 lock 哈希，而启动器版本不变。已安装的 profile 或 NixOS 系统还需要分别升级 profile 或重新构建系统。

注意：API 地址是可变地址，`flake.lock` 只记录内容哈希，不保存 JSON 本身。本机 Nix store 中保留快照时可以复用或回退；在没有该快照的新机器上，如果 API 内容已变，旧 lock 会因哈希不匹配而拒绝构建。此时需要刷新 input；若要求长期离线复现或跨机器回退，还需保存并分发对应的 input store 路径，或将发行 JSON 镜像到不可变的版本库地址。

检查与格式化：

```sh
nix flake check path:.
nix fmt -- flake.nix package.nix release.nix
```

构建和命令行检查不等同于登录、资源准备或实际游戏运行验证。
