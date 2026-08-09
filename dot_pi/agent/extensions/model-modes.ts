import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { DynamicBorder, getAgentDir } from "@earendil-works/pi-coding-agent";
import { Container, type SelectItem, SelectList, Text } from "@earendil-works/pi-tui";

const MODE_NAMES = ["exec", "think", "default"] as const;
const CONFIG_PATH = join(homedir(), ".pi", "model-modes.json");
const KEYBINDING_ID = "extension.modelModes.select";

type ModeName = (typeof MODE_NAMES)[number];
type ThinkingLevel = "off" | "minimal" | "low" | "medium" | "high" | "xhigh" | "max";
type Shortcut = Parameters<ExtensionAPI["registerShortcut"]>[0];

interface ModeConfig {
	provider: string;
	model: string;
	thinkingLevel: ThinkingLevel;
}

interface PersistedDefaults {
	defaultProvider?: string;
	defaultModel?: string;
	defaultThinkingLevel?: string;
}

type ModelModesConfig = Record<ModeName, ModeConfig>;

const THINKING_LEVELS = new Set<ThinkingLevel>(["off", "minimal", "low", "medium", "high", "xhigh", "max"]);

function loadConfig(): ModelModesConfig {
	if (!existsSync(CONFIG_PATH)) {
		throw new Error(`Config not found: ${CONFIG_PATH}`);
	}

	const parsed = JSON.parse(readFileSync(CONFIG_PATH, "utf8")) as Partial<Record<ModeName, Partial<ModeConfig>>>;
	const config = {} as ModelModesConfig;

	for (const name of MODE_NAMES) {
		const mode = parsed[name];
		if (!mode || typeof mode.provider !== "string" || typeof mode.model !== "string") {
			throw new Error(`Mode "${name}" must define provider and model`);
		}
		if (typeof mode.thinkingLevel !== "string" || !THINKING_LEVELS.has(mode.thinkingLevel as ThinkingLevel)) {
			throw new Error(`Mode "${name}" has an invalid thinkingLevel`);
		}
		config[name] = mode as ModeConfig;
	}

	return config;
}

function loadPersistedDefaults(): PersistedDefaults {
	const settings = JSON.parse(readFileSync(join(getAgentDir(), "settings.json"), "utf8")) as PersistedDefaults;
	return {
		defaultProvider: settings.defaultProvider,
		defaultModel: settings.defaultModel,
		defaultThinkingLevel: settings.defaultThinkingLevel,
	};
}

function restorePersistedDefaults(defaults: PersistedDefaults): void {
	const path = join(getAgentDir(), "settings.json");
	const settings = JSON.parse(readFileSync(path, "utf8")) as Record<string, unknown>;
	for (const key of ["defaultProvider", "defaultModel", "defaultThinkingLevel"] as const) {
		if (defaults[key] === undefined) delete settings[key];
		else settings[key] = defaults[key];
	}
	writeFileSync(path, `${JSON.stringify(settings, null, 2)}\n`);
}

function loadShortcuts(): Shortcut[] {
	const path = join(getAgentDir(), "keybindings.json");
	if (!existsSync(path)) return [];

	try {
		const config = JSON.parse(readFileSync(path, "utf8")) as Record<string, unknown>;
		const value = config[KEYBINDING_ID];
		if (typeof value === "string") return [value as Shortcut];
		if (Array.isArray(value)) return value.filter((key): key is string => typeof key === "string") as Shortcut[];
	} catch (error) {
		console.error(`model-modes: failed to read ${path}: ${error}`);
	}

	return [];
}

export default function modelModesExtension(pi: ExtensionAPI) {
	const persistedDefaults = loadPersistedDefaults();
	let activeMode: ModeName | undefined;
	let applyingMode = false;
	let lastContext: ExtensionContext | undefined;

	function updateStatus(ctx: ExtensionContext): void {
		ctx.ui.setStatus(
			"model-modes",
			activeMode ? ctx.ui.theme.fg("accent", `mode:${activeMode}`) : undefined,
		);
	}

	async function applyMode(name: ModeName, config: ModelModesConfig, ctx: ExtensionContext): Promise<void> {
		const selected = config[name];
		const model = ctx.modelRegistry.find(selected.provider, selected.model);
		if (!model) {
			ctx.ui.notify(`Model not found: ${selected.provider}/${selected.model}`, "error");
			return;
		}

		applyingMode = true;
		try {
			if (!(await pi.setModel(model))) {
				ctx.ui.notify(`No credentials for ${selected.provider}/${selected.model}`, "error");
				return;
			}
			pi.setThinkingLevel(selected.thinkingLevel);

			// Pi's public model APIs update global defaults. Let their queued writes
			// finish, then restore those fields so this switch stays session-only.
			await new Promise<void>((resolve) => setTimeout(resolve, 0));
			restorePersistedDefaults(persistedDefaults);

			activeMode = name;
			updateStatus(ctx);
			ctx.ui.notify(
				`${name}: ${selected.provider}/${selected.model} (${selected.thinkingLevel})`,
				"info",
			);
		} finally {
			applyingMode = false;
		}
	}

	async function showSelector(ctx: ExtensionContext): Promise<void> {
		let config: ModelModesConfig;
		try {
			config = loadConfig();
		} catch (error) {
			ctx.ui.notify(`model-modes: ${error instanceof Error ? error.message : String(error)}`, "error");
			return;
		}

		const items: SelectItem[] = MODE_NAMES.map((name) => {
			const mode = config[name];
			return {
				value: name,
				label: activeMode === name ? `${name} (active)` : name,
				description: `${mode.provider}/${mode.model} · ${mode.thinkingLevel}`,
			};
		});

		let result: string | null | undefined;
		if (ctx.mode === "tui") {
			result = await ctx.ui.custom<string | null>((tui, theme, _keybindings, done) => {
				const container = new Container();
				container.addChild(new DynamicBorder((text: string) => theme.fg("accent", text)));
				container.addChild(new Text(theme.fg("accent", theme.bold("Select model mode")), 1, 0));

				const list = new SelectList(items, items.length, {
					selectedPrefix: (text) => theme.fg("accent", text),
					selectedText: (text) => theme.fg("accent", text),
					description: (text) => theme.fg("muted", text),
					scrollInfo: (text) => theme.fg("dim", text),
					noMatch: (text) => theme.fg("warning", text),
				});
				list.onSelect = (item) => done(item.value);
				list.onCancel = () => done(null);
				container.addChild(list);
				container.addChild(new Text(theme.fg("dim", "↑↓ navigate • enter select • esc cancel"), 1, 0));
				container.addChild(new DynamicBorder((text: string) => theme.fg("accent", text)));

				return {
					render: (width: number) => container.render(width),
					invalidate: () => container.invalidate(),
					handleInput: (data: string) => {
						list.handleInput(data);
						tui.requestRender();
					},
				};
			});
		} else if (ctx.hasUI) {
			result = await ctx.ui.select("Select model mode", [...MODE_NAMES]);
		}

		if (result && MODE_NAMES.includes(result as ModeName)) {
			await applyMode(result as ModeName, config, ctx);
		}
	}

	pi.registerCommand("model-mode", {
		description: "Select a session-only model mode",
		handler: async (_args, ctx) => showSelector(ctx),
	});

	for (const shortcut of loadShortcuts()) {
		pi.registerShortcut(shortcut, {
			description: "Select a session-only model mode",
			handler: async (ctx) => showSelector(ctx),
		});
	}

	pi.on("session_start", (_event, ctx) => {
		lastContext = ctx;
		activeMode = undefined;
		updateStatus(ctx);
	});

	pi.on("model_select", () => {
		if (applyingMode) return;
		activeMode = undefined;
		if (lastContext) updateStatus(lastContext);
	});

	pi.on("thinking_level_select", () => {
		if (applyingMode) return;
		activeMode = undefined;
		if (lastContext) updateStatus(lastContext);
	});
}
