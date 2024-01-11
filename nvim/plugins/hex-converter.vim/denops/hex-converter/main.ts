import { Denops } from "https://deno.land/x/denops_std@v5.0.0/mod.ts";
import {
        echo,
        execute,
} from "https://deno.land/x/denops_std@v5.0.0/helper/mod.ts";
import {
        isArray,
        isNumber,
} from "https://deno.land/x/unknownutil@v2.1.1/mod.ts";
import * as unknownutil from "https://deno.land/x/unknownutil@v2.1.1/mod.ts";
import { assert } from "https://deno.land/std@0.65.0/testing/asserts.ts";
import * as fn from "https://deno.land/x/denops_std@v5.0.0/function/mod.ts";

export async function main(denops: Denops): Promise<void> {
        denops.dispatcher = {
                async getSelectedText(where: unknown): Promise<void> {
                        const begin = await fn.getpos(denops, "'<");
                        const end = await fn.getpos(denops, "'>");
                        const selectedLineContents = await fn.getline(
                                denops,
                                "'<",
                                "'>",
                        ) as Array<
                                string
                        >;
                        const beginLineNum = begin[1];
                        const beginColumnNum = Math.min(begin[2], selectedLineContents[0].length);
                        const endLineText: string = selectedLineContents.at(-1);
                        const endLineNum = end[1];
                        const endColumnNum = Math.min(end[2], endLineText.length);

                        const s = Array.from(selectedLineContents);
                        s[s.length - 1] = endLineText.substr(0, endColumnNum);
                        s[0] = s[0].substr(beginColumnNum - 1, s[0].length);
                        console.log(`selectedText: ${s}`);
                },
                async toHexEcho(where: unknown): Promise<void> {
                        unknownutil.assertNumber(where);
                        const n = where as number;
                        await echo(denops, n.toString(16));
                },
                async toHex(text: unknown): Promise<unknown> {
                        const selectedContent = await fn.getline(denops, "'<", "'>") as Array<
                                string
                        >;
                        const isVisualModel = selectedContent != undefined;

                        if (isVisualModel) {
                                const selectedContent = await fn.getline(denops, "'<", "'>") as Array<
                                        string
                                >;
                                for (let i = 0; i < selectedContent.length; i++) {
                                        convertToHex(selectedContent[i]);
                                }

                                if (selectedContent[0] != "") {
                                        const contents = selectedContent[0].split(",").map((v) =>
                                                Number(v.trim())
                                        );
                                        const hex_numbers = contents.map((v) => v.toString(16));
                                        return await Promise.resolve(hex_numbers.join(", "));
                                } else {
                                        assert(false);
                                }
                        } else {
                                const isNumberArrayArgs = isArray(text, isNumber);
                                const isNumberArg = isNumber(text);
                                assert(
                                        isNumberArrayArgs || isNumberArg,
                                        "args is not Array<number> | number",
                                );
                                if (isNumberArrayArgs) {
                                        const numbers = text as Array<number>;
                                        const hex_numbers = numbers.map((v) => v.toString(16));
                                        return await Promise.resolve(hex_numbers.join(", "));
                                } else if (isNumberArg) {
                                        const n = text as number;
                                        return await Promise.resolve(n.toString(16));
                                } else {
                                        return await Promise.resolve("");
                                }
                        }
                },
        };

        await execute(
                denops,
                `
command! -nargs=1 ConvertToHex echomsg denops#request('${denops.name}', 'toHexEcho', [<args>])
command! -range ToHex echomsg denops#request('${denops.name}', 'toHex', [<args>])
command! -range GetSelectedText echomsg denops#request('${denops.name}', 'getSelectedText', [<args>])
`,
        );
}

function convertToHex(text: string) {
        const regex = /((0x[0-9a-fA-F]+)|(0b[0-1]+)|([0-9]+))/g;
        const results = text.match(regex);
        console.log();
}
