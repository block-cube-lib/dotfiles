import {
  BaseConfig,
  type ConfigReturn,
} from "jsr:@shougo/dpp-vim@6.6.0/config";
import type { Dpp } from "jsr:@shougo/dpp-vim@6.6.0/dpp";
import type {
  ContextBuilder,
  Plugin,
} from "jsr:@shougo/dpp-vim@6.6.0/types";
import type { Denops } from "jsr:@denops/std@8.2.0";

type Toml = {
  ftplugins?: Record<string, string>;
  hooks_file?: string;
  plugins?: Plugin[];
}

type TomlLoadSetting = {
  path: string;
  lazy: boolean;
}

type LazyMakeStateResult = {
  plugins: Plugin[];
  stateLines: string[];
}

export class Config extends BaseConfig {
  override async config(args: {
    denops: Denops;
    contextBuilder: ContextBuilder;
    basePath: string;
    dpp: Dpp;
  }): Promise<ConfigReturn> {
    args.contextBuilder.setGlobal({
      protocols: ["git"],
    });

    const[context, options] = await args.contextBuilder.get(args.denops);

    // Load toml plugins
    const toml_dir = "$XDG_CONFIG_HOME/nvim/dpp/toml"
    const tomls: Toml[] = [];

    const toml_load_settings: TomlLoadSetting[] = [
      { path: `${toml_dir}/dpp.toml`, lazy: false, },
      { path: `${toml_dir}/common.toml`, lazy: false, },
      { path: `${toml_dir}/lazy.toml`, lazy: true, },
      { path: `${toml_dir}/ddu.toml`, lazy: true, },
      { path: `${toml_dir}/lsp.toml`, lazy: true, },
      { path: `${toml_dir}/ddc.toml`, lazy: true, },
    ];

    // Machine-local plugins (git-ignored): loaded only when the
    // file exists on this machine.
    const xdgConfigHome = Deno.env.get("XDG_CONFIG_HOME");
    const homeDir = Deno.env.get("HOME") ?? Deno.env.get("USERPROFILE") ?? "";
    const configHome = (xdgConfigHome && xdgConfigHome.length > 0)
      ? xdgConfigHome
      : `${homeDir}/.config`;
    try {
      const localToml = `${configHome}/nvim/dpp/toml/local.toml`;
      if (Deno.statSync(localToml).isFile) {
        toml_load_settings.push({ path: localToml, lazy: false });
      }
    } catch {
      // No local.toml on this machine: nothing to load.
    }

    for (const {path, lazy} of toml_load_settings) {
      console.log(`load ${path}`);
      const toml = await args.dpp.extAction(
        args.denops,
        context,
        options,
        "toml",
        "load",
        {
          path: path,
          options: {
            lazy: lazy,
          },
        },
      ) as Toml | undefined;
      if (toml) {
        tomls.push(toml);
        console.log(`push ${path}`);
      }
    }

    const record_plugins: Record<string, Plugin> = {};
    const ftplugins: Record<string, string> = {};
    const hooks_files: string[] = [];

    tomls.forEach((toml) => {
      for (const plugin of toml.plugins ?? []) {
        record_plugins[plugin.name] = plugin;
      }
      if (toml.ftplugins) {
        for (const [ft, name] of Object.entries(toml.ftplugins)) {
          if (ftplugins[ft]) {
            ftplugins[ft] += `\n${name}`;
          }
          else {
            ftplugins[ft] = name;
          }
        }
      }
      if (toml.hooks_file) {
        hooks_files.push(toml.hooks_file);
      }
    });

    const lazy_result = await args.dpp.extAction(
      args.denops,
      context,
      options,
      "lazy",
      "makeState",
      {
        plugins: Object.values(record_plugins),
      },
    ) as LazyMakeStateResult | undefined;

    console.log(lazy_result);

    if (!lazy_result) {
      throw new Error("dpp-ext-lazy makeState returned no result");
    }

    return {
      plugins: lazy_result.plugins,
      stateLines: lazy_result.stateLines,
    };
  }
}
