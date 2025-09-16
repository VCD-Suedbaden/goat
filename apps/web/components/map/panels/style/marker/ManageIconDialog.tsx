import { Button, Dialog, DialogActions, DialogContent, DialogTitle } from "@mui/material";

import { ICON_NAME } from "@p4b/ui/components/Icon";

import { useTranslation } from "@/i18n/client";

import type { Marker } from "@/lib/validations/layer";

import NoValuesFound from "@/components/map/common/NoValuesFound";

type ManageIconsDialogProps = {
  open: boolean;
  onClose: () => void;
  markers: Marker[];
  renderIconGrid: (markers: Marker[]) => React.ReactNode;
};

export const ManageIconsDialog = ({ open, onClose, markers, renderIconGrid }: ManageIconsDialogProps) => {
  const { t } = useTranslation("common");

  return (
    <Dialog open={open} onClose={onClose} fullWidth>
      <DialogTitle>{t("manage_icons")}</DialogTitle>
      <DialogContent>
        {markers.length ? (
          renderIconGrid(markers)
        ) : (
          <NoValuesFound text={t("no_custom_icons")} icon={ICON_NAME.IMAGE} />
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>{t("close")}</Button>
      </DialogActions>
    </Dialog>
  );
};
