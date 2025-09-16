import ClearIcon from "@mui/icons-material/Clear";
import {
  Box,
  Button,
  Divider,
  IconButton,
  InputAdornment,
  Stack,
  Tab,
  Tabs,
  TextField,
  Tooltip,
  Typography,
} from "@mui/material";
import { useMemo, useState } from "react";

import { ICON_NAME } from "@p4b/ui/components/Icon";

import { useTranslation } from "@/i18n/client";

import { useAssets } from "@/lib/api/assets";
import { MAKI_ICONS_BASE_URL, MAKI_ICON_SIZE, MAKI_ICON_TYPES } from "@/lib/constants/icons";
import { assetTypeEnum } from "@/lib/validations/assets";
import type { Marker } from "@/lib/validations/layer";

import NoValuesFound from "@/components/map/common/NoValuesFound";
import { ManageIconsDialog } from "@/components/map/panels/style/marker/ManageIconDialog";
import { UploadIconDialog } from "@/components/map/panels/style/marker/UploadIconDialog";
import { MaskedImageIcon } from "@/components/map/panels/style/other/MaskedImageIcon";

type MarkerGalleryProps = {
  selectedMarker?: Marker | undefined;
  onSelectMarker?: (marker: Marker) => void;
};

const MarkerGallery = (props: MarkerGalleryProps) => {
  const [search, setSearch] = useState("");
  const [tab, setTab] = useState<"library" | "custom">(props.selectedMarker?.source ?? "library");
  const [uploadDialogOpen, setUploadDialogOpen] = useState(false);
  const [manageDialogOpen, setManageDialogOpen] = useState(false);
  const { t } = useTranslation("common");

  // Fetch custom assets
  const { assets: rawAssets = [], mutate: mutateAssets } = useAssets({ asset_type: assetTypeEnum.Enum.icon });

  // Map assets into our Marker type
  const customMarkers: Marker[] = useMemo(
    () =>
      rawAssets.map((asset) => ({
        id: asset.id,
        name: asset.display_name || asset.file_name,
        url: asset.url,
        category: asset.category || undefined,
        source: "custom",
      })),
    [rawAssets]
  );

  // Filter library icons
  const filteredGroups = useMemo(() => {
    if (!search.trim()) return MAKI_ICON_TYPES;
    const lower = search.toLowerCase();
    return MAKI_ICON_TYPES.map((group) => ({
      ...group,
      icons: group.icons.filter((icon) => icon.toLowerCase().includes(lower)),
    })).filter((group) => group.icons.length > 0);
  }, [search]);

  // Filter custom markers
  const filteredCustomMarkers = useMemo(() => {
    if (!search.trim()) return customMarkers;
    const lower = search.toLowerCase();
    return customMarkers.filter(
      (marker) => marker.name.toLowerCase().includes(lower) || marker.url.toLowerCase().includes(lower)
    );
  }, [search, customMarkers]);

  // Render icons
  const renderIconGrid = (icons: Marker[]) => (
    <Box sx={{ display: "flex", flexWrap: "wrap" }}>
      {icons.map((marker, idx) => {
        const isSelected = props.selectedMarker?.url === marker.url;
        return (
          <Tooltip
            key={`${marker.name}-${idx}`}
            title={marker.name}
            arrow
            placement="top"
            PopperProps={{ disablePortal: true }}>
            <Box
              onClick={() => props.onSelectMarker?.(marker)}
              sx={{
                cursor: "pointer",
                m: 0.5,
                p: 0.8,
                borderRadius: 1,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                border: "2px solid",
                borderColor: isSelected ? "primary.main" : "transparent",
                bgcolor: isSelected ? "action.selected" : "transparent",
                "&:hover": {
                  bgcolor: "action.hover",
                },
              }}>
              <MaskedImageIcon
                imageUrl={marker.url}
                dimension={`${MAKI_ICON_SIZE}px`}
                applyMask={marker?.source === "custom" ? false : true}
              />
            </Box>
          </Tooltip>
        );
      })}
    </Box>
  );

  return (
    <Box sx={{ display: "flex", flexDirection: "column" }}>
      {/* Tabs */}
      <Tabs value={tab} onChange={(_, value) => setTab(value)} variant="fullWidth">
        <Tab value="library" label={t("library")} />
        <Tab value="custom" label={t("custom")} />
      </Tabs>

      {/* Search bar */}
      {(tab === "library" || (tab === "custom" && customMarkers.length > 0)) && (
        <>
          <Box sx={{ px: 2, pt: 4 }}>
            <TextField
              size="small"
              placeholder={t("search_icons")}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              fullWidth
              InputProps={{
                endAdornment: search && (
                  <InputAdornment position="end">
                    <IconButton size="small" onClick={() => setSearch("")}>
                      <ClearIcon fontSize="small" />
                    </IconButton>
                  </InputAdornment>
                ),
              }}
            />
          </Box>
          <Divider sx={{ py: 1 }} />
        </>
      )}

      {/* Scrollable content */}
      <Box sx={{ maxHeight: 280, overflowY: "auto", px: 2, py: 2 }}>
        {tab === "library" && (
          <>
            {filteredGroups.map((group, groupIndex) => (
              <Stack key={`${group.name}-${groupIndex}`} direction="column" sx={{ mb: 2 }} spacing={2}>
                <Stack>
                  <Typography variant="body2" fontWeight="bold">
                    {group.name}
                  </Typography>
                  <Divider sx={{ mb: 1 }} />
                </Stack>
                {renderIconGrid(
                  group.icons.map((icon) => ({
                    name: icon,
                    url: `${MAKI_ICONS_BASE_URL}/${icon}.svg`,
                    category: group.name,
                    source: "library",
                  }))
                )}
              </Stack>
            ))}
            {filteredGroups.length === 0 && (
              <NoValuesFound text={t("no_icons_found")} icon={ICON_NAME.IMAGE} />
            )}
          </>
        )}

        {tab === "custom" && (
          <>
            {filteredCustomMarkers.length ? (
              renderIconGrid(filteredCustomMarkers)
            ) : (
              <NoValuesFound text={t("no_custom_icons")} icon={ICON_NAME.IMAGE} />
            )}

            {/* Buttons for managing custom icons */}
            <Divider sx={{ my: 2 }} />
            <Stack direction="row" justifyContent="space-between" sx={{ mb: 2, mt: 4 }}>
              <Button size="small" variant="text" onClick={() => setUploadDialogOpen(true)}>
                {t("upload_icon")}
              </Button>
              <Button size="small" variant="text" onClick={() => setManageDialogOpen(true)}>
                {t("manage_icons")}
              </Button>
            </Stack>
          </>
        )}
      </Box>

      {/* Dialogs */}
      <UploadIconDialog
        open={uploadDialogOpen}
        onClose={() => setUploadDialogOpen(false)}
        onUploaded={() => {
          mutateAssets();
          setTab("custom");
        }}
      />
      <ManageIconsDialog
        open={manageDialogOpen}
        onClose={() => setManageDialogOpen(false)}
        markers={customMarkers}
        renderIconGrid={renderIconGrid}
      />
    </Box>
  );
};

export default MarkerGallery;
