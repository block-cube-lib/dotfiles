import type { Entrypoint } from "jsr:@denops/std@7.0.0";
import { v4 } from "jsr:@std/uuid";
import { assert } from "jsr:@std/assert";

export const main: Entrypoint = (denops) => {
  denops.dispatcher = {
    async init() {
      const { name } = denops;
      await denops.cmd(
        `command! Uuid4 echomsg denops#request('${name}', 'request_uuid', [])`,
      );
      await denops.cmd(
        `inoremap <C-u> <Cmd>call denops#request('${name}', 'insert_generated_uuid', [])<CR>`,
      );
    },

    request_uuid(): string {
      const uuid = crypto.randomUUID();
      assert(v4.validate(uuid));
      return uuid;
    },

    async insert_generated_uuid(): Promise<void> {
      const uuid = this.request_uuid([]);
      await denops.call('nvim_input', uuid);
    },
  };
};
