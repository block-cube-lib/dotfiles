import {
  BaseConfig,
  ContextBuilder,
  Dpp,
  Plugin,
} from "https://deno.land/x/dpp_vim@v0.1.0/types.ts";
import { Denops, fn } from "https://deno.land/x/dpp_vim@v0.1.0/deps.ts";

type Toml = {
  hooks_file?: string;
  ftplugins?: Record<string, string>;
  plugins: Plugin[];
}

type LazyMakeStaetResult = {
  plugins: Plugin[];
  stateLines: string[];
}

export class Config extends BaseConfig {
  override async config(args: {
    denops: Denops;
    contextBuilder: ContextBuilder;
    basePath: string;
    dpp: Dpp;
  }): Promise<{
    plugins: Plugin[];
    stateLines: string[];
  }> {
    args.contextBuilder.setGlobal({
      protocols: ["git"],
    });
  }

  const[context, options] = await args.contextBuilder.get(args.denops);

// Load toml plugins
const tomls: Toml[] = [];
const toml = await args.dpp.extAction(
  args.denops,
  context,
  options,
  "toml",
  "load",
  {
    path: "$XDG_CONFIG_HOME/nvim/dpp.toml",
    options: {
      lazy: false,
    },
  },
) as Toml | undefined;
if (toml) {
  tomls.push();
}
}
