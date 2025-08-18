import type { Denops, EntryPoint } from "jsr:@denops/std@7.0.0";
import { assert, is } from "jsr:@core/unknownutil@3.18.1";

async function convertNumber(denops: Denops, fromBase: 10 | 16, toBase: 10 | 16): Promise<void> {
  const [start, _end] = await denops.call('nvim_buf_get_mark', denops.bufnr, '<', {}) as [number, number];
  const [endLine, _endCol] = await denops.call('nvim_buf_get_mark', denops.bufnr, '>', {}) as [number, number];
  const lines = await denops.call('nvim_buf_get_lines', denops.bufnr, start - 1, endLine, true) as string[];

  const convertedLines: string[] = [];
  for (const [_i, line] of lines.entries()) {
    const newLine = line.replace(/\b(0x[0-9a-fA-F]+|\d+)\b/g, (match) => {
      let num: number;
      if (match.startsWith('0x')) {
        if (fromBase === 16) {
          num = parseInt(match.slice(2), 16);
        } else {
          return match; // 変換元が16進数でない場合はそのまま
        }
      } else {
        if (fromBase === 10) {
          num = parseInt(match, 10);
        } else {
          return match; // 変換元が10進数でない場合はそのまま
        }
      }

      if (toBase === 16) {
        return `0x${num.toString(16).toUpperCase()}`;
      } else {
        return num.toString(10);
      }
    });
    convertedLines.push(newLine);
  }

  await denops.call('nvim_buf_set_lines', denops.bufnr, start - 1, endLine, true, convertedLines);
}

export const main: EntryPoint = (denops: Denops) => {
  denops.dispatcher = {
    async init() {
      await denops.cmd(
        `command! -range=% HexToDec call denops#request('${denops.name}', 'hexToDec', [<range>])`,
      );
      await denops.cmd(
        `command! -range=% DecToHex call denops#request('${denops.name}', 'decToHex', [<range>])`,
      );
    },

    async hexToDec(_range: string) {
      await convertNumber(denops, 16, 10);
    },

    async decToHex(_range: string) {
      await convertNumber(denops, 10, 16);
    },
  };
};
