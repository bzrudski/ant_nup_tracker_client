/*
 * exceptions.dart
 * Copyright (c) 2020-2022, Abouheif Lab.
 *
 * AntNupTracker, mobile app for recording and managing ant nuptial flight data
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

abstract class LocalisableException implements Exception {
  String getLocalisedName(BuildContext context);
  String getLocalisedDescription(BuildContext context);
}

class ReadException implements LocalisableException {
  final int status;
  ReadException(this.status);

  @override
  String toString() => "Read Exception: Server returned status $status";

  @override
  String getLocalisedDescription(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.readExceptionBody(status);
  }

  @override
  String getLocalisedName(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.readExceptionHeader;
  }
}

class JsonException implements LocalisableException {
  @override
  String getLocalisedDescription(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.jsonExceptionBody;
  }

  @override
  String getLocalisedName(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.jsonExceptionHeader;
  }
}

class GetException implements LocalisableException {
  final int status;
  GetException(this.status);

  @override
  String toString() => "Get Exception: Server returned status $status";

  @override
  String getLocalisedDescription(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.getExceptionBody(status);
  }

  @override
  String getLocalisedName(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.getExceptionHeader;
  }
}

class InvalidIdException implements LocalisableException {
  @override
  String getLocalisedDescription(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.invalidIdExceptionBody;
  }

  @override
  String getLocalisedName(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.invalidIdExceptionHeader;
  }
}

class NoFlightException implements LocalisableException {
  final int id;

  NoFlightException(this.id);

  @override
  String getLocalisedDescription(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.noFlightExceptionBody(id);
  }

  @override
  String getLocalisedName(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.noFlightExceptionHeader;
  }
}

class NoImageException implements LocalisableException {
  final int id;

  NoImageException(this.id);

  @override
  String getLocalisedDescription(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.noImageExceptionBody(id);
  }

  @override
  String getLocalisedName(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.noImageExceptionHeader;
  }
}

class InvalidImageTypeException implements LocalisableException {
  final String? mimeType;

  InvalidImageTypeException([this.mimeType]);

  @override
  String getLocalisedDescription(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.invalidImageTypeExceptionBody(mimeType ?? "none");
  }

  @override
  String getLocalisedName(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.invalidImageTypeExceptionHeader;
  }
}

class NoResponseException implements LocalisableException {
  @override
  String getLocalisedDescription(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.noResponseExceptionBody;
  }

  @override
  String getLocalisedName(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.noResponseExceptionHeader;
  }
}

class FailedAuthenticationException implements LocalisableException {
  @override
  String getLocalisedDescription(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.failedAuthenticationExceptionBody;
  }

  @override
  String getLocalisedName(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.failedAuthenticationExceptionHeader;
  }
}

class NoWeatherException implements LocalisableException {
  final int _id;

  const NoWeatherException(this._id);

  @override
  String getLocalisedDescription(BuildContext context) {
    return AppLocalizations.of(context)!.noWeatherExceptionBody(_id);
  }

  @override
  String getLocalisedName(BuildContext context) {
    return AppLocalizations.of(context)!.noWeatherExceptionHeader;
  }
}

class EmptyUsernamePasswordException implements LocalisableException {
  @override
  String getLocalisedDescription(BuildContext context) {
    return AppLocalizations.of(context)!.emptyUsernamePasswordExceptionBody;
  }

  @override
  String getLocalisedName(BuildContext context) {
    return AppLocalizations.of(context)!.emptyUsernamePasswordExceptionHeader;
  }
}

class IncorrectCredentialsException implements LocalisableException {
  @override
  String getLocalisedDescription(BuildContext context) {
    return AppLocalizations.of(context)!.incorrectCredentialsExceptionBody;
  }

  @override
  String getLocalisedName(BuildContext context) {
    return AppLocalizations.of(context)!.incorrectCredentialsExceptionHeader;
  }
}

class ForbiddenAccessException implements LocalisableException {
  @override
  String getLocalisedDescription(BuildContext context) {
    return AppLocalizations.of(context)!.forbiddenAccessExceptionBody;
  }

  @override
  String getLocalisedName(BuildContext context) {
    return AppLocalizations.of(context)!.forbiddenAccessExceptionHeader;
  }
}

class InsufficientPrivilegesException implements LocalisableException {
  @override
  String getLocalisedDescription(BuildContext context) {
    return AppLocalizations.of(context)!.insufficientPrivilegesExceptionBody;
  }

  @override
  String getLocalisedName(BuildContext context) {
    return AppLocalizations.of(context)!.insufficientPrivilegesExceptionHeader;
  }
}

class LoginException implements LocalisableException {
  final int status;

  LoginException(this.status);

  @override
  String getLocalisedDescription(BuildContext context) {
    return AppLocalizations.of(context)!.loginExceptionBody(status);
  }

  @override
  String getLocalisedName(BuildContext context) {
    return AppLocalizations.of(context)!.loginExceptionHeader;
  }
}

class LogoutException implements LocalisableException {
  final int status;

  LogoutException(this.status);

  @override
  String getLocalisedDescription(BuildContext context) {
    return AppLocalizations.of(context)!.logoutExceptionBody(status);
  }

  @override
  String getLocalisedName(BuildContext context) {
    return AppLocalizations.of(context)!.logoutExceptionHeader;
  }
}

class AddFlightException implements LocalisableException {
  final int _status;

  AddFlightException(this._status);

  @override
  String getLocalisedDescription(BuildContext context) {
    return AppLocalizations.of(context)!.addFlightExceptionBody(_status);
  }

  @override
  String getLocalisedName(BuildContext context) {
    return AppLocalizations.of(context)!.addFlightExceptionHeader;
  }

}

class EditFlightException implements LocalisableException {
  final int _status;

  EditFlightException(this._status);

  @override
  String getLocalisedDescription(BuildContext context) {
    return AppLocalizations.of(context)!.editFlightExceptionBody(_status);
  }

  @override
  String getLocalisedName(BuildContext context) {
    return AppLocalizations.of(context)!.editFlightExceptionHeader;
  }

}

class CommentCreationException implements LocalisableException {
  final int _status;

  CommentCreationException(this._status);

  @override
  String getLocalisedDescription(BuildContext context) {
    return AppLocalizations.of(context)!.commentCreationExceptionBody(_status);
  }

  @override
  String getLocalisedName(BuildContext context) {
    return AppLocalizations.of(context)!.commentCreationExceptionHeader;
  }

}

class FlightVerificationException implements LocalisableException {
  final int _status;

  FlightVerificationException(this._status);

  @override
  String getLocalisedDescription(BuildContext context) {
    return AppLocalizations.of(context)!.flightVerificationExceptionBody(_status);
  }

  @override
  String getLocalisedName(BuildContext context) {
    return AppLocalizations.of(context)!.flightVerificationExceptionHeader;
  }

}

class ImageCreationException implements LocalisableException {
  final int _status;

  ImageCreationException(this._status);

  @override
  String getLocalisedDescription(BuildContext context) {
    return AppLocalizations.of(context)!.imageCreationExceptionBody(_status);
  }

  @override
  String getLocalisedName(BuildContext context) {
    return AppLocalizations.of(context)!.imageCreationExceptionHeader;
  }

}

class ImageDeletionException implements LocalisableException {
  final int _status;

  ImageDeletionException(this._status);

  @override
  String getLocalisedDescription(BuildContext context) {
    return AppLocalizations.of(context)!.imageDeletionExceptionBody(_status);
  }

  @override
  String getLocalisedName(BuildContext context) {
    return AppLocalizations.of(context)!.imageDeletionExceptionHeader;
  }

}

class NotImageRowException implements LocalisableException {
  @override
  String getLocalisedDescription(BuildContext context) {
    return AppLocalizations.of(context)!.notImageRowExceptionBody;
  }

  @override
  String getLocalisedName(BuildContext context) {
    return AppLocalizations.of(context)!.notImageRowExceptionHeader;
  }
}

class NotificationUpdateException implements LocalisableException {
  final int _status;

  NotificationUpdateException(this._status);

  @override
  String getLocalisedDescription(BuildContext context) {
    return AppLocalizations.of(context)!.notificationUpdateExceptionBody(_status);
  }

  @override
  String getLocalisedName(BuildContext context) {
    return AppLocalizations.of(context)!.notificationUpdateExceptionHeader;
  }

}

class TokenVerificationException implements LocalisableException {
  final int _status;

  TokenVerificationException(this._status);

  @override
  String getLocalisedDescription(BuildContext context) {
    return AppLocalizations.of(context)!.tokenVerificationExceptionBody(_status);
  }

  @override
  String getLocalisedName(BuildContext context) {
    return AppLocalizations.of(context)!.tokenVerificationExceptionHeader;
  }

}

class GenusNotFoundException implements LocalisableException {
  final int id;

  GenusNotFoundException(this.id);

  @override
  String getLocalisedDescription(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.genusNotFoundExceptionBody(id);
  }

  @override
  String getLocalisedName(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.genusNotFoundExceptionHeader;
  }
}

class NoFlightResultsException implements LocalisableException {
  @override
  String getLocalisedDescription(BuildContext context) {
    return AppLocalizations.of(context)!.noFlightResultsExceptionBody;
  }

  @override
  String getLocalisedName(BuildContext context) {
    return AppLocalizations.of(context)!.noFlightResultsExceptionHeader;
  }
}

class ExceptionWidget extends StatelessWidget {
  final LocalisableException _exception;
  final void Function()? _tryAgainAction;
  final IconData _iconData;

  const ExceptionWidget(this._exception, this._tryAgainAction, {Key? key, IconData icon = Icons.error})
      : _iconData = icon, super(key: key);

  @override
  Widget build(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    // final _labelStyle =
    //     Theme.of(context).textTheme.bodyText2!.apply(fontSizeDelta: 4.0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              _iconData,
              size: 96,
              color: Theme.of(context).colorScheme.primary,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _exception.getLocalisedName(context),
                    // style: Theme.of(context).textTheme.headline5,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _exception.getLocalisedDescription(context),
                    // style: _labelStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            if (_tryAgainAction != null) TextButton(
              onPressed: () {
                _tryAgainAction!();
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(appLocalization.tryAgainButton),
              ),
            )
          ],
        ),
      ),
    );
  }
}
